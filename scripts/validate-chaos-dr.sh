#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"

"${repository_root}/scripts/fetch-phase4-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-phase11-dependencies.sh" >/dev/null
mkdir -p "${schema_cache_dir}"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

"${repository_root}/scripts/render-gitops.sh" "${repository_root}/platform/cert-manager" \
  >"${validation_dir}/cert-manager.yaml"
"${repository_root}/scripts/render-gitops.sh" "${repository_root}/platform/chaos-mesh" \
  >"${validation_dir}/chaos-first.yaml"
"${repository_root}/scripts/render-gitops.sh" "${repository_root}/platform/chaos-mesh" \
  >"${validation_dir}/chaos-second.yaml"
cmp "${validation_dir}/chaos-first.yaml" "${validation_dir}/chaos-second.yaml"
kustomize build "${repository_root}/platform/chaos-mesh/experiments" \
  >"${validation_dir}/experiments-first.yaml"
kustomize build "${repository_root}/platform/chaos-mesh/experiments" \
  >"${validation_dir}/experiments-second.yaml"
cmp "${validation_dir}/experiments-first.yaml" "${validation_dir}/experiments-second.yaml"

helm lint "${repository_root}/.cache/phase11/chaos-mesh" \
  --values <("${repository_root}/scripts/render-config.sh" \
    "${repository_root}/platform/chaos-mesh/configure-chaos-mesh.yaml")

kubeconform -strict -summary -cache "${schema_cache_dir}" -kubernetes-version 1.36.5 \
  -ignore-missing-schemas "${validation_dir}/chaos-first.yaml"

extract_schema() {
  local kind="$1" version="$2" manifest="$3"
  local output="${schema_dir}/${kind,,}-${version}.json"
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .spec.names.kind == \"${kind}\") | .spec.versions[] | select(.name == \"${version}\") | .schema.openAPIV3Schema" \
    "${manifest}" >"${output}"
  test -s "${output}"
}

for kind in PodChaos NetworkChaos StressChaos IOChaos; do
  extract_schema "${kind}" v1alpha1 "${validation_dir}/chaos-first.yaml"
done
extract_schema Certificate v1 "${validation_dir}/cert-manager.yaml"
extract_schema Issuer v1 "${validation_dir}/cert-manager.yaml"

kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' "${validation_dir}/experiments-first.yaml"
yq eval-all 'select(.kind == "Certificate" or .kind == "Issuer")' \
  "${validation_dir}/chaos-first.yaml" >"${validation_dir}/chaos-certificates.yaml"
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' "${validation_dir}/chaos-certificates.yaml"

test "$(yq eval-all '[select(.kind == "Namespace" and .metadata.annotations."chaos-mesh.org/inject" == "enabled")] | length' "${validation_dir}/chaos-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Namespace" and .metadata.annotations."chaos-mesh.org/inject" == "enabled") | select(.metadata.name != "chaos-testing")] | length' "${validation_dir}/chaos-first.yaml")" = 0
test "$(yq eval-all '[select(.apiVersion == "chaos-mesh.org/v1alpha1")] | length' "${validation_dir}/chaos-first.yaml")" = 0
test "$(yq eval-all '[select(.apiVersion == "chaos-mesh.org/v1alpha1" and (.metadata.namespace != "chaos-testing" or (.spec.selector.namespaces | contains(["chaos-testing"]) | not)))] | length' "${validation_dir}/experiments-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "PodChaos")] | length' "${validation_dir}/experiments-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkChaos")] | length' "${validation_dir}/experiments-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "StressChaos")] | length' "${validation_dir}/experiments-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "IOChaos")] | length' "${validation_dir}/experiments-first.yaml")" = 1

test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "chaos-controller-manager") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null or .securityContext.runAsNonRoot != true or .securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' "${validation_dir}/chaos-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "DaemonSet" and .metadata.name == "chaos-daemon") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null or .securityContext.privileged != true)] | length' "${validation_dir}/chaos-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "chaos-target") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null or .securityContext.runAsNonRoot != true or .securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' "${validation_dir}/chaos-first.yaml")" = 0

kube-linter lint --exclude privileged-container --exclude privilege-escalation-container \
  --exclude drop-net-raw-capability --exclude no-read-only-root-fs --exclude host-pid \
  --exclude sensitive-host-mounts --exclude non-existent-service-account \
  --exclude run-as-non-root \
  "${validation_dir}/chaos-first.yaml"

for script in "${repository_root}"/apps/sentinel/tests/load/*.js; do
  k6 inspect "${script}" >/dev/null
done

drills=(
  node-power-off-under-traffic.md recover-etcd-quorum.md restore-etcd-from-s3.md
  postgres-failover-and-pitr.md restore-namespace-with-velero.md rebuild-single-node.md
  rebuild-bare-metal-cluster.md
)
for drill in "${drills[@]}"; do
  file="${repository_root}/docs/dr/${drill}"
  grep -q 'Status: \*\*PENDING HARDWARE\*\*' "${file}"
  grep -q '^## Preconditions$' "${file}"
  grep -q '^## Procedure$' "${file}"
  grep -q '^## Rollback$' "${file}"
  grep -q '^## Results$' "${file}"
done

printf 'Phase 11 Chaos Mesh boundaries, experiments, load scenarios, and DR drills validated.\n'
