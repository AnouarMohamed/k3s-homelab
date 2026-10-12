#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"

"${repository_root}/scripts/fetch-phase4-dependencies.sh"
"${repository_root}/scripts/fetch-phase6-dependencies.sh"
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

render_twice "${repository_root}/clusters/homelab/bootstrap/runtime-secrets" prerequisites
render_twice "${repository_root}/platform/openbao" openbao
render_twice "${repository_root}/platform/external-secrets" external-secrets
render_twice "${repository_root}/platform/runtime-secrets" runtime-secrets
"${repository_root}/scripts/render-gitops.sh" \
  "${repository_root}/platform/cert-manager" >"${validation_dir}/cert-manager.yaml"

helm lint "${repository_root}/.cache/phase6/openbao" \
  --values "${repository_root}/platform/openbao/configure-openbao.yaml"
helm lint "${repository_root}/.cache/phase6/external-secrets" \
  --values "${repository_root}/platform/external-secrets/configure-external-secrets.yaml"

for manifest in prerequisites openbao external-secrets runtime-secrets; do
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

extract_schema Certificate v1 "${validation_dir}/cert-manager.yaml"
extract_schema Issuer v1 "${validation_dir}/cert-manager.yaml"
extract_schema ClusterSecretStore v1 "${validation_dir}/external-secrets-first.yaml"

yq eval-all \
  'select(.kind == "Certificate" or .kind == "Issuer" or .kind == "ClusterSecretStore")' \
  "${validation_dir}/prerequisites-first.yaml" \
  "${validation_dir}/runtime-secrets-first.yaml" >"${validation_dir}/custom-resources.yaml"
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' \
  "${validation_dir}/custom-resources.yaml"

for manifest in openbao external-secrets; do
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$") | not)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
done

test "$(yq eval-all '[select(.kind == "StatefulSet" and .metadata.name == "openbao" and .spec.replicas == 3 and (.spec.volumeClaimTemplates | length) == 2)] | length' \
  "${validation_dir}/openbao-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.name == "openbao")] | length' \
  "${validation_dir}/openbao-first.yaml")" -ge 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "external-secrets")] | length' \
  "${validation_dir}/external-secrets-first.yaml")" -ge 3
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.namespace == "external-secrets" and .spec.replicas == 2)] | length' \
  "${validation_dir}/external-secrets-first.yaml")" = 3
test "$(yq eval-all '[select(.kind == "ClusterSecretStore" and .metadata.name == "openbao" and .spec.provider.vault.auth.kubernetes.serviceAccountRef.audiences[0] == "openbao")] | length' \
  "${validation_dir}/runtime-secrets-first.yaml")" = 1
test "$(yq '.spec.clusterResourceWhitelist[] | select(has("name"))' \
  "${repository_root}/clusters/homelab/projects/restrict-runtime-secrets-project.yaml")" = ""

grep -q 'audit "file" "file"' "${repository_root}/platform/openbao/configure-openbao.yaml"
grep -q 'storage "raft"' "${repository_root}/platform/openbao/configure-openbao.yaml"
grep -q 'runtime-secret-operator' \
  "${repository_root}/platform/openbao/resources/apply-openbao-configuration.sh"
grep -q 'capabilities = \["create", "update"\]' \
  "${repository_root}/platform/openbao/resources/operator-write.hcl"
if grep -Eq 'read|delete|list|patch|sudo' \
  "${repository_root}/platform/openbao/resources/operator-write.hcl"; then
  printf 'OpenBao rotation policy exceeds create/update capabilities.\n' >&2
  exit 1
fi

kube-linter lint --exclude dangling-service \
  "${validation_dir}/openbao-first.yaml"
kube-linter lint \
  "${validation_dir}/external-secrets-first.yaml" \
  "${validation_dir}/runtime-secrets-first.yaml"

printf 'Phase 6 runtime-secret resources rendered deterministically and validated.\n'
