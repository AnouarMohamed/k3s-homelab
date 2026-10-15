#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"
ci_command_type_query='[.. | select(tag == "!!map") |
  (.script[]?, .before_script[]?, .after_script[]?) |
  select(tag != "!!str")] | length'

for pipeline_file in \
  "${repository_root}/.gitlab-ci.yml" \
  "${repository_root}/ci/sentinel.gitlab-ci.yml"; do
  test "$(yq "${ci_command_type_query}" "${pipeline_file}")" = 0
done

"${repository_root}/scripts/fetch-cilium-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-storage-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-secrets-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-observability-dependencies.sh" >/dev/null
"${repository_root}/scripts/fetch-sentinel-dependencies.sh" >/dev/null
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

render_twice "${repository_root}/platform/argo-rollouts" argo-rollouts
render_twice "${repository_root}/platform/cloudnative-pg" cloudnative-pg
render_twice "${repository_root}/platform/external-secrets" external-secrets
render_twice "${repository_root}/observability/prometheus-stack" prometheus-stack
render_twice "${repository_root}/observability/sloth" sloth
render_twice "${repository_root}/apps/sentinel/overlays/prod" sentinel-prod
render_twice "${repository_root}/apps/sentinel/overlays/staging" sentinel-staging

test "$(yq eval-all '[select(.kind == "CiliumNetworkPolicy" and .metadata.name == "allow-controller-kubernetes-api") | .spec.egress[].toEntities[] | select(. == "kube-apiserver")] | length' \
  "${validation_dir}/argo-rollouts-first.yaml")" = 1

helm lint "${repository_root}/.cache/sentinel/argo-rollouts" \
  --values "${repository_root}/platform/argo-rollouts/configure-argo-rollouts.yaml"

for manifest in argo-rollouts sentinel-prod sentinel-staging; do
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

extract_schema Rollout v1alpha1 "${validation_dir}/argo-rollouts-first.yaml"
extract_schema AnalysisTemplate v1alpha1 "${validation_dir}/argo-rollouts-first.yaml"
extract_schema Cluster v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ScheduledBackup v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ObjectStore v1 "${validation_dir}/cloudnative-pg-first.yaml"
extract_schema ExternalSecret v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema SecretStore v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema ServiceMonitor v1 "${validation_dir}/prometheus-stack-first.yaml"
extract_schema PrometheusRule v1 "${validation_dir}/prometheus-stack-first.yaml"
extract_schema PrometheusServiceLevel v1 "${validation_dir}/sloth-first.yaml"
extract_schema HTTPRoute v1 \
  "${repository_root}/.cache/cilium/gateway-api-standard-v1.6.1.yaml"

for environment in prod staging; do
  yq eval-all '
    select(
      .kind == "AnalysisTemplate" or
      .kind == "Cluster" or
      .kind == "ExternalSecret" or
      .kind == "HTTPRoute" or
      .kind == "ObjectStore" or
      .kind == "PrometheusRule" or
      .kind == "PrometheusServiceLevel" or
      .kind == "Rollout" or
      .kind == "ScheduledBackup" or
      .kind == "SecretStore" or
      .kind == "ServiceMonitor"
    )' "${validation_dir}/sentinel-${environment}-first.yaml" \
    >"${validation_dir}/sentinel-${environment}-custom.yaml"
  sed -i 's/CHANGE_ME_DOMAIN/example.invalid/g' \
    "${validation_dir}/sentinel-${environment}-custom.yaml"
  kubeconform -strict -summary \
    -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
    -reject '*' \
    "${validation_dir}/sentinel-${environment}-custom.yaml"
done

for environment in prod staging; do
  manifest="${validation_dir}/sentinel-${environment}-first.yaml"
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "Rollout") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' "${manifest}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "Rollout") | .spec.template.spec.containers[] | select(.securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' "${manifest}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "Rollout") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$") | not)] | length' "${manifest}")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "Rollout") | .spec.template.spec.containers[] | select(.image | test("[A-Z]"))] | length' "${manifest}")" = 0
  test "$(yq eval-all '[select(.kind == "NetworkPolicy")] | length' "${manifest}")" = 3
  test "$(yq eval-all '[select(.kind == "CiliumNetworkPolicy" and .metadata.name == "allow-database-kubernetes-api") | .spec.egress[].toEntities[] | select(. == "kube-apiserver")] | length' "${manifest}")" = 1
  test "$(yq eval-all '[select(.kind == "HorizontalPodAutoscaler" and .metadata.name == "sentinel-api")] | length' "${manifest}")" = 1
  test "$(yq eval-all '[select(.kind == "PodDisruptionBudget" and .metadata.name == "sentinel-api")] | length' "${manifest}")" = 1
  test "$(yq eval-all '[select(.kind == "PrometheusServiceLevel" and .spec.service == "sentinel-api")] | length' "${manifest}")" = 1
done

test "$(yq eval-all '[select(.kind == "Rollout" and .metadata.namespace == "apps-sentinel" and .spec.replicas == 3 and .spec.strategy.canary.steps != null)] | length' "${validation_dir}/sentinel-prod-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Cluster" and .metadata.namespace == "apps-sentinel" and .spec.instances == 3)] | length' "${validation_dir}/sentinel-prod-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "HTTPRoute" and .metadata.namespace == "apps-sentinel" and .spec.parentRefs[0].name == "public")] | length' "${validation_dir}/sentinel-prod-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "HTTPRoute" and .metadata.namespace == "apps-sentinel") | .spec.rules[].matches[] | select(.path.type != "Exact" or (.path.value == "/metrics" or .path.value == "/healthz" or .path.value == "/readyz"))] | length' "${validation_dir}/sentinel-prod-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "HTTPRoute" and .metadata.namespace == "apps-sentinel") | .spec.rules[].matches[].path.value] | length' "${validation_dir}/sentinel-prod-first.yaml")" = 4
test "$(yq eval-all '[select(.kind == "Rollout" and .metadata.namespace == "apps-sentinel-staging" and .spec.replicas == 1)] | length' "${validation_dir}/sentinel-staging-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Cluster" and .metadata.namespace == "apps-sentinel-staging" and .spec.instances == 1)] | length' "${validation_dir}/sentinel-staging-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "HTTPRoute" and .metadata.namespace == "apps-sentinel-staging" and .spec.parentRefs[0].name == "internal")] | length' "${validation_dir}/sentinel-staging-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "PodDisruptionBudget" and .metadata.namespace == "apps-sentinel-staging" and .spec.maxUnavailable == 1 and .spec.minAvailable == null)] | length' "${validation_dir}/sentinel-staging-first.yaml")" = 1

for environment in prod staging; do
  yq eval-all --output-format=yaml \
    '[.] | {"groups": [.[] | select(.kind == "PrometheusRule") | .spec.groups[]]}' \
    "${validation_dir}/sentinel-${environment}-first.yaml" \
    >"${validation_dir}/sentinel-${environment}-rules.yaml"
  promtool check rules "${validation_dir}/sentinel-${environment}-rules.yaml"
  dashboard="$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "sentinel-dashboard") | .data."sentinel.json"' "${validation_dir}/sentinel-${environment}-first.yaml")"
  yq --input-format=json '.' <<<"${dashboard}" >/dev/null
done

kube-linter lint \
  --exclude dangling-service \
  --exclude minimum-three-replicas \
  "${validation_dir}/sentinel-prod-first.yaml" \
  "${validation_dir}/sentinel-staging-first.yaml"

k6 inspect "${repository_root}/apps/sentinel/tests/load/test-status-api.js" >/dev/null

(
  cd "${repository_root}/apps/sentinel"
  go vet ./...
  go test -race ./...
  go build ./cmd/api ./cmd/worker
)

printf 'Sentinel application, delivery resources, and rollout controls validated.\n'
