#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"

"${repository_root}/scripts/fetch-secrets-dependencies.sh"
"${repository_root}/scripts/fetch-observability-dependencies.sh"
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

components=(
  bootstrap
  runtime-secrets
  prometheus-stack
  blackbox
  loki
  alloy
  tempo
  otel-collector
  sloth
  resources
  argocd-notifications
)
for component in "${components[@]}"; do
  render_twice "${repository_root}/observability/${component}" "${component}"
done
render_twice "${repository_root}/platform/external-secrets" external-secrets
render_twice "${repository_root}/platform/argocd" argocd

charts=(
  kube-prometheus-stack
  blackbox-exporter
  loki
  alloy
  tempo
  otel-collector
  sloth
)
value_files=(
  prometheus-stack/configure-prometheus-stack.yaml
  blackbox/configure-blackbox-exporter.yaml
  loki/configure-loki.yaml
  alloy/configure-alloy.yaml
  tempo/configure-tempo.yaml
  otel-collector/configure-otel-collector.yaml
  sloth/configure-sloth.yaml
)
for index in "${!charts[@]}"; do
  helm lint "${repository_root}/.cache/observability/${charts[$index]}" \
    --values "${repository_root}/observability/${value_files[$index]}"
done

for component in "${components[@]}"; do
  kubeconform -strict -summary \
    -cache "${schema_cache_dir}" \
    -kubernetes-version 1.36.5 \
    -ignore-missing-schemas \
    "${validation_dir}/${component}-first.yaml"
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

monitoring_kinds=(
  Alertmanager
  AlertmanagerConfig
  PodMonitor
  Probe
  Prometheus
  PrometheusRule
  ServiceMonitor
)
for kind in "${monitoring_kinds[@]}"; do
  version=v1
  [[ "${kind}" == AlertmanagerConfig ]] && version=v1alpha1
  extract_schema "${kind}" "${version}" \
    "${validation_dir}/prometheus-stack-first.yaml"
done
extract_schema ExternalSecret v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema SecretStore v1 "${validation_dir}/external-secrets-first.yaml"
extract_schema PrometheusServiceLevel v1 "${validation_dir}/sloth-first.yaml"

yq eval-all '
  select(
    .kind == "Alertmanager" or
    .kind == "AlertmanagerConfig" or
    .kind == "ExternalSecret" or
    .kind == "PodMonitor" or
    .kind == "Probe" or
    .kind == "Prometheus" or
    .kind == "PrometheusRule" or
    .kind == "PrometheusServiceLevel" or
    .kind == "SecretStore" or
    .kind == "ServiceMonitor"
  )' "${validation_dir}"/*-first.yaml \
  >"${validation_dir}/custom-resources.yaml"
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' \
  "${validation_dir}/custom-resources.yaml"

strict_workloads=(
  prometheus-stack
  blackbox
  loki
  alloy
  tempo
  otel-collector
  sloth
)
for manifest in "${strict_workloads[@]}"; do
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet") | .spec.template.spec.containers[] | select(.securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "DaemonSet" or .kind == "StatefulSet" or .kind == "Job") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$") | not)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
done

test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "monitoring")] | length' \
  "${validation_dir}"/*-first.yaml)" -ge 2
test "$(yq eval-all '[select(.kind == "Prometheus" and .spec.replicas == 2 and .spec.retention == "15d" and .spec.retentionSize == "18GB")] | length' \
  "${validation_dir}/prometheus-stack-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Alertmanager" and .spec.replicas == 3)] | length' \
  "${validation_dir}/prometheus-stack-first.yaml")" = 1
grafana_ini="$(yq eval-all --unwrapScalar \
  'select(.kind == "ConfigMap" and .metadata.name == "monitoring-grafana") | .data["grafana.ini"]' \
  "${validation_dir}/prometheus-stack-first.yaml")"
grep -Fxq 'preinstall_disabled = true' <<<"${grafana_ini}"
grep -Fxq 'preinstall_auto_update = false' <<<"${grafana_ini}"
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "blackbox-prometheus-blackbox-exporter" and .spec.replicas == 2)] | length' \
  "${validation_dir}/blackbox-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "alloy" and .spec.replicas == 2)] | length' \
  "${validation_dir}/alloy-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "otel-collector-opentelemetry-collector" and .spec.replicas == 2)] | length' \
  "${validation_dir}/otel-collector-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "argocd-notifications-controller") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$"))] | length' \
  "${validation_dir}/argocd-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "PrometheusServiceLevel" and .spec.service == "prometheus-api" and .spec.slos[0].objective == 99.9)] | length' \
  "${validation_dir}/resources-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ClusterRole" and .metadata.name == "sloth") | .rules[] | select((.resources | contains(["*"])) or (.verbs | contains(["*"])))] | length' \
  "${validation_dir}/sloth-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "ClusterRole" and .metadata.name == "sloth") | .rules[]] | length' \
  "${validation_dir}/sloth-first.yaml")" = 3
test "$(yq eval-all '[select(.kind == "PrometheusRule" and .metadata.name == "homelab-platform-alerts") | .spec.groups[].rules[] | select(.alert == "Watchdog")] | length' \
  "${validation_dir}/resources-first.yaml")" = 1

yq eval-all --output-format=yaml \
  '[.] | {"groups": [.[] | select(.kind == "PrometheusRule") | .spec.groups[]]}' \
  "${validation_dir}/resources-first.yaml" \
  >"${validation_dir}/prometheus-rules.yaml"
test "$(yq '.groups | length' "${validation_dir}/prometheus-rules.yaml")" -ge 1
promtool check rules "${validation_dir}/prometheus-rules.yaml"

dashboard_count=0
overview_dashboard=''
while IFS= read -r dashboard_key; do
  dashboard="$(DASHBOARD_KEY="${dashboard_key}" yq eval-all --unwrapScalar \
    'select(.kind == "ConfigMap" and .metadata.name == "homelab-platform-dashboards") | .data[strenv(DASHBOARD_KEY)]' \
    "${validation_dir}/resources-first.yaml")"
  yq --input-format=json '.' <<<"${dashboard}" >/dev/null
  yq --input-format=json --output-format=yaml \
    '{"groups": [{"name": "dashboard.promql", "rules": ([.. | select(tag == "!!map" and has("expr")) | .expr] | to_entries | map({"record": ("dashboard_query_" + (.key | tostring)), "expr": .value}))}]}' \
    <<<"${dashboard}" >"${validation_dir}/dashboard-rules.yaml"
  promtool check rules "${validation_dir}/dashboard-rules.yaml" >/dev/null
  if [[ "${dashboard_key}" == overview.json ]]; then
    overview_dashboard="${dashboard}"
  fi
  dashboard_count=$((dashboard_count + 1))
done < <(yq eval-all --unwrapScalar \
  'select(.kind == "ConfigMap" and .metadata.name == "homelab-platform-dashboards") | .data | keys | .[]' \
  "${validation_dir}/resources-first.yaml")
test "${dashboard_count}" = 7
test -n "${overview_dashboard}"
test "$(yq --input-format=json '.uid' <<<"${overview_dashboard}")" = homelab-overview
test "$(yq --input-format=json '[.. | select(tag == "!!map" and (.type == "stat" or .type == "timeseries"))] | length' \
  <<<"${overview_dashboard}")" -ge 20
test "$(yq --input-format=json '[.. | select(tag == "!!map" and .type == "stat" and .fieldConfig.defaults.noValue != "Unknown")] | length' \
  <<<"${overview_dashboard}")" = 0
test "$(yq --input-format=json '[.. | select(tag == "!!map" and (.type == "stat" or .type == "timeseries") and (.description == null or .description == ""))] | length' \
  <<<"${overview_dashboard}")" = 0
if grep -Eq 'Running pods|count\(longhorn_volume_state\)|cnpg_pg_database_size_bytes' \
  <<<"${overview_dashboard}"; then
  printf 'Overview dashboard contains a rejected inventory or vanity metric.\n' >&2
  exit 1
fi

runbook="${repository_root}/docs/runbooks/respond-to-platform-alerts.md"
sed -n 's/^## //p' "${runbook}" | \
  tr '[:upper:]' '[:lower:]' | \
  sed -E 's/[^a-z0-9 -]//g; s/ +/ /g; s/ /-/g' \
  >"${validation_dir}/runbook-fragments"
while IFS= read -r fragment; do
  grep -Fxq -- "${fragment}" "${validation_dir}/runbook-fragments"
done < <(yq eval-all --unwrapScalar \
  '.. | select(tag == "!!map" and has("runbook_url")) | .runbook_url' \
  "${validation_dir}/resources-first.yaml" | sed '/^---$/d; s/^.*#//' | sort --unique)

test "$(yq eval-all '[select(.kind == "AlertmanagerConfig" and .spec.receivers[0].webhookConfigs[0].urlSecret.name == "alertmanager-notification")] | length' \
  "${validation_dir}/runtime-secrets-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ExternalSecret" and .metadata.name == "argocd-notifications" and .spec.target.name == "argocd-notifications-secret")] | length' \
  "${validation_dir}/argocd-notifications-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ServiceMonitor" and .metadata.name == "openbao" and .metadata.namespace == "openbao" and .spec.endpoints[0].port == "https" and .spec.endpoints[0].tlsConfig.ca.secret.name == "openbao-server-tls")] | length' \
  "${validation_dir}/resources-first.yaml")" = 1

for manifest in "${strict_workloads[@]}"; do
  if [[ "${manifest}" == prometheus-stack ]]; then
    kube-linter lint \
      --exclude dangling-service \
      --exclude host-network \
      --exclude host-pid \
      --exclude sensitive-host-mounts \
      "${validation_dir}/${manifest}-first.yaml"
    continue
  fi
  kube-linter lint --exclude minimum-three-replicas \
    "${validation_dir}/${manifest}-first.yaml"
done
kube-linter lint \
  "${validation_dir}/runtime-secrets-first.yaml" \
  "${validation_dir}/resources-first.yaml" \
  "${validation_dir}/argocd-notifications-first.yaml"

printf 'Observability metrics, logs, traces, probes, dashboards, alerts, and SLOs validated.\n'
