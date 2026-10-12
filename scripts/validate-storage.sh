#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"

"${repository_root}/scripts/fetch-phase5-dependencies.sh"
mkdir -p "${schema_cache_dir}"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

render_twice() {
  local source_path="$1"
  local output_name="$2"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" \
    >"${validation_dir}/${output_name}-first.yaml"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" \
    >"${validation_dir}/${output_name}-second.yaml"
  cmp "${validation_dir}/${output_name}-first.yaml" \
    "${validation_dir}/${output_name}-second.yaml"
}

render_twice "${repository_root}/platform/snapshot-controller" snapshot-controller
render_twice "${repository_root}/platform/longhorn" longhorn
render_twice "${repository_root}/platform/cloudnative-pg" cloudnative-pg
render_twice "${repository_root}/platform/velero" velero
render_twice "${repository_root}/platform/storage-verification" storage-verification

# shellcheck disable=SC1091
source "${repository_root}/platform/snapshot-controller/dependencies.env"
printf '%s  %s\n' "${SNAPSHOT_CLASS_CRD_SHA256}" \
  "${repository_root}/platform/snapshot-controller/upstream/define-volume-snapshotclasses.yaml" | sha256sum --check
printf '%s  %s\n' "${SNAPSHOT_CRD_SHA256}" \
  "${repository_root}/platform/snapshot-controller/upstream/define-volume-snapshots.yaml" | sha256sum --check
printf '%s  %s\n' "${SNAPSHOT_CONTENT_CRD_SHA256}" \
  "${repository_root}/platform/snapshot-controller/upstream/define-volume-snapshotcontents.yaml" | sha256sum --check
printf '%s  %s\n' "${SNAPSHOT_RBAC_SHA256}" \
  "${repository_root}/platform/snapshot-controller/upstream/authorize-snapshot-controller.yaml" | sha256sum --check
printf '%s  %s\n' "${SNAPSHOT_DEPLOYMENT_SHA256}" \
  "${repository_root}/platform/snapshot-controller/upstream/deploy-snapshot-controller.yaml" | sha256sum --check

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/longhorn/configure-longhorn.yaml" \
  >"${validation_dir}/longhorn-values.yaml"
helm lint "${repository_root}/.cache/phase5/longhorn" \
  --values "${validation_dir}/longhorn-values.yaml"
helm lint "${repository_root}/.cache/phase5/cloudnative-pg" \
  --values "${repository_root}/platform/cloudnative-pg/configure-cloudnative-pg.yaml"
helm lint "${repository_root}/.cache/phase5/plugin-barman-cloud" \
  --values "${repository_root}/platform/cloudnative-pg/configure-barman-cloud.yaml"
set -a
# shellcheck disable=SC1091
source "${repository_root}/platform/velero/dependencies.env"
set +a
"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/velero/configure-velero.yaml" \
  >"${validation_dir}/velero-values.yaml"
helm lint "${repository_root}/.cache/phase5/velero" \
  --values "${validation_dir}/velero-values.yaml"

for manifest in snapshot-controller longhorn cloudnative-pg velero storage-verification; do
  kubeconform -strict -summary \
    -cache "${schema_cache_dir}" \
    -kubernetes-version 1.36.5 \
    -ignore-missing-schemas \
    "${validation_dir}/${manifest}-first.yaml"
done

extract_schema() {
  local kind="$1"
  local version="$2"
  local manifest="$3"
  local output="${schema_dir}/${kind,,}-${version}.json"
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .spec.names.kind == \"${kind}\") | .spec.versions[] | select(.name == \"${version}\") | .schema.openAPIV3Schema" \
    "${manifest}" >"${output}"
  test -s "${output}"
}

extract_schema VolumeSnapshotClass v1 "${validation_dir}/snapshot-controller-first.yaml"
extract_schema RecurringJob v1beta2 "${validation_dir}/longhorn-first.yaml"
extract_schema Cluster v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ScheduledBackup v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ObjectStore v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema BackupStorageLocation v1 "${validation_dir}/velero-first.yaml"
extract_schema Schedule v1 "${validation_dir}/velero-first.yaml"

yq eval-all \
  'select(.kind == "VolumeSnapshotClass" or .kind == "RecurringJob" or .kind == "Cluster" or .kind == "ScheduledBackup" or .kind == "ObjectStore" or .kind == "BackupStorageLocation" or .kind == "Schedule")' \
  "${validation_dir}"/*-first.yaml >"${validation_dir}/custom-resources.yaml"
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' \
  "${validation_dir}/custom-resources.yaml"

strict_workloads=(snapshot-controller cloudnative-pg velero storage-verification)
for manifest in "${strict_workloads[@]}"; do
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
done

test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet" or .kind == "Job" or .kind == "CronJob") | (.spec.template.spec.containers // .spec.jobTemplate.spec.template.spec.containers // [])[] | select(.image | test(":latest($|@)"))] | length' \
  "${validation_dir}"/*-first.yaml)" = 0
test "$(yq eval-all '[select(.kind == "ConfigMap" and .metadata.name == "longhorn-storageclass") | .data."storageclass.yaml" | from_yaml | select(.kind == "StorageClass" and .metadata.name == "longhorn" and .metadata.annotations."storageclass.kubernetes.io/is-default-class" == "true" and .parameters.numberOfReplicas == "3")] | length' \
  "${validation_dir}/longhorn-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "StorageClass" and .metadata.name == "local-path" and .metadata.annotations."storageclass.kubernetes.io/is-default-class" == "false")] | length' \
  "${validation_dir}/longhorn-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "RecurringJob")] | length' \
  "${validation_dir}/longhorn-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "Cluster" and .metadata.name == "storage-verification" and .spec.instances == 3)] | length' \
  "${validation_dir}/cloudnative-pg-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Schedule")] | length' \
  "${validation_dir}/velero-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "cnpg-system")] | length' \
  "${validation_dir}/cloudnative-pg-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "storage-verification")] | length' \
  "${validation_dir}/cloudnative-pg-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "velero")] | length' \
  "${validation_dir}/velero-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "kube-system")] | length' \
  "${validation_dir}/snapshot-controller-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "longhorn-system")] | length' \
  "${validation_dir}/longhorn-first.yaml")" -ge 1

for secret_file in "${repository_root}"/clusters/homelab/bootstrap/storage-secrets/*.sops.yaml; do
  test "$(sops filestatus "${secret_file}" | yq --input-format=json '.encrypted')" = true
  test "$(yq --unwrapScalar '.sops.age[0].recipient' "${secret_file}")" = \
    "$(yq --unwrapScalar '.creation_rules[0].age' "${repository_root}/.sops.yaml")"
done

kube-linter lint \
  "${validation_dir}/snapshot-controller-first.yaml" \
  "${validation_dir}/cloudnative-pg-first.yaml" \
  "${validation_dir}/velero-first.yaml" \
  "${validation_dir}/storage-verification-first.yaml"

printf 'Phase 5 storage and backup resources rendered deterministically and validated.\n'
