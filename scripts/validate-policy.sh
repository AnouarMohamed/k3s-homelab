#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
schema_cache_dir="${repository_root}/.cache/kubeconform"
# shellcheck disable=SC1091
source "${repository_root}/policies/dependencies.env"

"${repository_root}/scripts/fetch-phase7-dependencies.sh"
"${repository_root}/scripts/fetch-phase8-dependencies.sh"
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

render_twice "${repository_root}/policies/bootstrap" bootstrap
render_twice "${repository_root}/policies/kyverno" kyverno
render_twice "${repository_root}/policies/trivy" trivy
render_twice "${repository_root}/policies/standards/audit" audit
render_twice "${repository_root}/policies/standards/enforce" enforce
render_twice "${repository_root}/policies/resources" resources
render_twice "${repository_root}/observability/prometheus-stack" prometheus-stack

helm lint "${repository_root}/.cache/phase8/kyverno" \
  --values "${repository_root}/policies/kyverno/configure-kyverno.yaml"
helm lint "${repository_root}/.cache/phase8/trivy-operator" \
  --values "${repository_root}/policies/trivy/configure-trivy-operator.yaml"

for manifest in bootstrap kyverno trivy audit enforce resources; do
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

extract_schema ClusterPolicy v1 "${validation_dir}/kyverno-first.yaml"
extract_schema ImageValidatingPolicy v1 "${validation_dir}/kyverno-first.yaml"
extract_schema ValidatingPolicy v1 "${validation_dir}/kyverno-first.yaml"
extract_schema ClusterComplianceReport v1alpha1 "${validation_dir}/trivy-first.yaml"
extract_schema PrometheusRule v1 "${validation_dir}/prometheus-stack-first.yaml"
extract_schema ServiceMonitor v1 "${validation_dir}/prometheus-stack-first.yaml"

for manifest in kyverno trivy audit enforce resources; do
  yq eval-all '
    select(
      .kind == "ClusterComplianceReport" or
      .kind == "ClusterPolicy" or
      .kind == "ImageValidatingPolicy" or
      .kind == "PrometheusRule" or
      .kind == "ServiceMonitor" or
      .kind == "ValidatingPolicy"
    )' "${validation_dir}/${manifest}-first.yaml" \
    >"${validation_dir}/${manifest}-custom.yaml"
  if test -s "${validation_dir}/${manifest}-custom.yaml"; then
    kubeconform -strict -summary \
      -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
      -reject '*' \
      "${validation_dir}/${manifest}-custom.yaml"
  fi
done

for manifest in kyverno trivy; do
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet" or .kind == "DaemonSet") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet" or .kind == "DaemonSet" or .kind == "Job") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
  test "$(yq eval-all '[select(.kind == "Deployment" or .kind == "StatefulSet" or .kind == "DaemonSet" or .kind == "Job") | .spec.template.spec.containers[] | select(.image | test("@sha256:[a-f0-9]{64}$") | not)] | length' \
    "${validation_dir}/${manifest}-first.yaml")" = 0
done

test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "kyverno-admission-controller" and .spec.replicas == 3)] | length' \
  "${validation_dir}/kyverno-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "Deployment" and (.metadata.name == "kyverno-background-controller" or .metadata.name == "kyverno-cleanup-controller" or .metadata.name == "kyverno-reports-controller") and .spec.replicas == 2)] | length' \
  "${validation_dir}/kyverno-first.yaml")" = 3
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "trivy-operator" and .spec.replicas == 2)] | length' \
  "${validation_dir}/trivy-first.yaml")" = 1
for image in \
  "${KYVERNO_IMAGE}" \
  "${KYVERNO_PRE_IMAGE}" \
  "${KYVERNO_BACKGROUND_IMAGE}" \
  "${KYVERNO_CLEANUP_IMAGE}" \
  "${KYVERNO_REPORTS_IMAGE}" \
  "${KYVERNO_CLI_IMAGE}" \
  "${KYVERNO_READINESS_IMAGE}"; do
  export EXPECTED_POLICY_IMAGE="${image}"
  test "$(yq eval-all '[.. | select(tag == "!!map" and has("image")) | select(.image == strenv(EXPECTED_POLICY_IMAGE))] | length' \
    "${validation_dir}/kyverno-first.yaml")" -ge 1
done
export EXPECTED_POLICY_IMAGE="${TRIVY_OPERATOR_IMAGE}"
test "$(yq eval-all '[.. | select(tag == "!!map" and has("image")) | select(.image == strenv(EXPECTED_POLICY_IMAGE))] | length' \
  "${validation_dir}/trivy-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and (.metadata.namespace == "kyverno" or .metadata.namespace == "trivy-system"))] | length' \
  "${validation_dir}/resources-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "Namespace") | select(.metadata.labels."pod-security.kubernetes.io/enforce" == "restricted" and .metadata.labels."pod-security.kubernetes.io/enforce-version" == "v1.36")] | length' \
  "${validation_dir}/bootstrap-first.yaml")" = 2
mapfile -t namespace_files < <(rg -l '^kind: Namespace$' "${repository_root}" --glob '*.yaml')
test "$(yq eval-all '[select(.kind == "Namespace") | select(
  .metadata.labels."pod-security.kubernetes.io/enforce" == null or
  .metadata.labels."pod-security.kubernetes.io/enforce-version" != "v1.36" or
  .metadata.labels."pod-security.kubernetes.io/audit" == null or
  .metadata.labels."pod-security.kubernetes.io/audit-version" != "v1.36" or
  .metadata.labels."pod-security.kubernetes.io/warn" == null or
  .metadata.labels."pod-security.kubernetes.io/warn-version" != "v1.36"
)] | length' "${namespace_files[@]}")" = 0

test "$(yq eval-all '[select(.kind == "ValidatingPolicy" or .kind == "ImageValidatingPolicy") | select(.spec.validationActions[0] != "Audit")] | length' \
  "${validation_dir}/audit-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "ValidatingPolicy" or .kind == "ImageValidatingPolicy") | select(.spec.validationActions[0] != "Deny")] | length' \
  "${validation_dir}/enforce-first.yaml")" = 0
test "$(yq eval-all '[select(.kind == "ClusterPolicy" and .metadata.name == "require-network-policy" and .spec.validationFailureAction == "Audit")] | length' \
  "${validation_dir}/audit-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ClusterPolicy" and .metadata.name == "require-network-policy" and .spec.validationFailureAction == "Enforce")] | length' \
  "${validation_dir}/enforce-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ValidatingPolicy" and .spec.matchConstraints.namespaceSelector.matchLabels."policy.homelab.dev/profile" == "application")] | length' \
  "${validation_dir}/audit-first.yaml")" = 5
test "$(yq eval-all '[select(.kind == "ValidatingPolicy" and .metadata.name == "restrict-image-registries" and .spec.matchConstraints.namespaceSelector.matchLabels."policy.homelab.dev/supply-chain" == "signed")] | length' \
  "${validation_dir}/audit-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "ImageValidatingPolicy" and .spec.attestors[0].cosign.keyless.identities[0].issuer == "https://gitlab.com" and .spec.matchImageReferences[0].glob == "registry.gitlab.com/CHANGE_ME_GITLAB_PROJECT_PATH/homelab-sentinel-*")] | length' \
  "${validation_dir}/audit-first.yaml")" = 1

test "$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "trivy-operator-trivy-config") | .data."trivy.repository" + ":" + .data."trivy.tag"' \
  "${validation_dir}/trivy-first.yaml")" = "${TRIVY_SCANNER_IMAGE}"
test "$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "trivy-operator") | .data."policies.bundle.oci.ref"' \
  "${validation_dir}/trivy-first.yaml")" = "${TRIVY_CHECKS_BUNDLE}"
test "$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "trivy-operator") | .data."node.collector.imageRef"' \
  "${validation_dir}/trivy-first.yaml")" = "${TRIVY_NODE_COLLECTOR_IMAGE}"

dashboard="$(yq eval-all --unwrapScalar 'select(.kind == "ConfigMap" and .metadata.name == "homelab-security-posture-dashboard") | .data."security-posture.json"' \
  "${validation_dir}/resources-first.yaml")"
yq --input-format=json '.' <<<"${dashboard}" >/dev/null
yq eval-all --output-format=yaml \
  '[.] | {"groups": [.[] | select(.kind == "PrometheusRule") | .spec.groups[]]}' \
  "${validation_dir}/resources-first.yaml" >"${validation_dir}/security-rules.yaml"
promtool check rules "${validation_dir}/security-rules.yaml"

kyverno test "${repository_root}/policies/tests" \
  --require-tests --warnings-as-errors --remove-color

kube-linter lint --exclude minimum-three-replicas \
  "${validation_dir}/kyverno-first.yaml" \
  "${validation_dir}/trivy-first.yaml" \
  "${validation_dir}/resources-first.yaml"

printf 'Phase 8 admission policy, supply-chain checks, and posture resources validated.\n'
