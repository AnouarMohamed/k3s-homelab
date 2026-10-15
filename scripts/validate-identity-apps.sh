#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"

"${repository_root}/scripts/fetch-cilium-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-storage-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-secrets-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-observability-dependencies.sh" >/dev/null
mkdir -p "${schema_cache_dir}"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

render_twice() {
  local source_path="$1"
  local output_name="$2"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" >"${validation_dir}/${output_name}-first.yaml"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" >"${validation_dir}/${output_name}-second.yaml"
  cmp "${validation_dir}/${output_name}-first.yaml" "${validation_dir}/${output_name}-second.yaml"
}

render_twice "${repository_root}/platform/cloudnative-pg" cloudnative-pg
render_twice "${repository_root}/platform/external-secrets" external-secrets
render_twice "${repository_root}/observability/prometheus-stack" prometheus-stack
render_twice "${repository_root}/platform/keycloak/resources" keycloak
render_twice "${repository_root}/apps/vaultwarden/overlays/prod" vaultwarden
render_twice "${repository_root}/apps/homepage/overlays/prod" homepage
render_twice "${repository_root}/apps/uptime-kuma/overlays/prod" uptime-kuma

for manifest in keycloak vaultwarden homepage uptime-kuma; do
  kubeconform -strict -summary -cache "${schema_cache_dir}" -kubernetes-version 1.36.5 \
    -ignore-missing-schemas "${validation_dir}/${manifest}-first.yaml"
done

extract_schema() {
  local kind="$1" version="$2" manifest="$3"
  local output="${schema_dir}/${kind,,}-${version}.json"
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .spec.names.kind == \"${kind}\") | .spec.versions[] | select(.name == \"${version}\") | .schema.openAPIV3Schema" \
    "${manifest}" >"${output}"
  test -s "${output}"
}

extract_schema Cluster v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ScheduledBackup v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ObjectStore v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ExternalSecret v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema SecretStore v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema ServiceMonitor v1 "${validation_dir}/prometheus-stack-first.yaml"
extract_schema PrometheusRule v1 "${validation_dir}/prometheus-stack-first.yaml"
extract_schema HTTPRoute v1 "${repository_root}/.cache/cilium/gateway-api-standard-v1.6.1.yaml"

for manifest in keycloak vaultwarden homepage uptime-kuma; do
  yq eval-all 'select(.kind == "Cluster" or .kind == "ScheduledBackup" or .kind == "ObjectStore" or .kind == "ExternalSecret" or .kind == "SecretStore" or .kind == "ServiceMonitor" or .kind == "PrometheusRule" or .kind == "HTTPRoute")' \
    "${validation_dir}/${manifest}-first.yaml" >"${validation_dir}/${manifest}-custom.yaml"
  sed -i 's/CHANGE_ME_DOMAIN/example.invalid/g; s/CHANGE_ME_GITLAB_PROJECT_PATH/example\/homelab/g' \
    "${validation_dir}/${manifest}-custom.yaml"
  kubeconform -strict -summary \
    -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
    -reject '*' "${validation_dir}/${manifest}-custom.yaml"
done

for manifest in keycloak vaultwarden homepage uptime-kuma; do
  rendered="${validation_dir}/${manifest}-first.yaml"
  test "$(yq eval-all '[select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' "${rendered}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.securityContext.runAsNonRoot != true or .securityContext.allowPrivilegeEscalation != false or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' "${rendered}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name != "keycloak") | .spec.template.spec.containers[] | select(.securityContext.readOnlyRootFilesystem != true)] | length' "${rendered}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$") | not)] | length' "${rendered}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment")] | length' "${rendered}")" -le "$(yq eval-all '[select(.kind == "NetworkPolicy")] | length' "${rendered}")"
  test "$(yq eval-all '[select(.kind == "HTTPRoute") | select(.spec.parentRefs[0].name != "internal")] | length' "${rendered}")" = 0
done

test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "keycloak" and .spec.replicas == 2)] | length' "${validation_dir}/keycloak-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "keycloak") | .spec.template.spec.containers[] | select(.securityContext.readOnlyRootFilesystem == false)] | length' "${validation_dir}/keycloak-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Cluster" and .metadata.name == "keycloak-database" and .spec.instances == 3)] | length' "${validation_dir}/keycloak-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Cluster" and .metadata.name == "vaultwarden-database" and .spec.instances == 3)] | length' "${validation_dir}/vaultwarden-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "CiliumNetworkPolicy" and .metadata.name == "allow-database-kubernetes-api") | .spec.egress[].toEntities[] | select(. == "kube-apiserver")] | length' "${validation_dir}/keycloak-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "CiliumNetworkPolicy" and .metadata.name == "allow-database-kubernetes-api") | .spec.egress[].toEntities[] | select(. == "kube-apiserver")] | length' "${validation_dir}/vaultwarden-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "PersistentVolumeClaim")] | length' "${validation_dir}/vaultwarden-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "PersistentVolumeClaim")] | length' "${validation_dir}/uptime-kuma-first.yaml")" = 1

realm="$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "keycloak-homelab-realm") | .data."homelab-realm.json"' "${validation_dir}/keycloak-first.yaml")"
jq empty <<<"${realm}"
jq -e '.requiredActions[] | select(.alias == "CONFIGURE_TOTP" and .defaultAction == true)' <<<"${realm}" >/dev/null
jq -e '[.clients[].protocolMappers[] | select(.config."claim.name" == "groups")] | length == 2' <<<"${realm}" >/dev/null

for manifest in keycloak vaultwarden homepage uptime-kuma; do
  yq eval-all --output-format=yaml '[.] | {"groups": [.[] | select(.kind == "PrometheusRule") | .spec.groups[]]}' \
    "${validation_dir}/${manifest}-first.yaml" >"${validation_dir}/${manifest}-rules.yaml"
  promtool check rules "${validation_dir}/${manifest}-rules.yaml"
done

kube-linter lint --exclude dangling-service --exclude minimum-three-replicas \
  --exclude no-read-only-root-fs \
  "${validation_dir}/keycloak-first.yaml" "${validation_dir}/vaultwarden-first.yaml" \
  "${validation_dir}/homepage-first.yaml" "${validation_dir}/uptime-kuma-first.yaml"

printf 'Identity, SSO configuration, applications, backups, and policy boundaries validated.\n'
