#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/phase2"

# shellcheck disable=SC1091
source "${repository_root}/platform/cilium/dependencies.env"

"${repository_root}/scripts/fetch-phase2-dependencies.sh"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

yq eval-all --output-format=json \
  'select(.kind == "CustomResourceDefinition" and .metadata.name == "gatewayclasses.gateway.networking.k8s.io") | .spec.versions[] | select(.name == "v1") | .schema.openAPIV3Schema' \
  "${cache_dir}/gateway-api-standard-${GATEWAY_API_VERSION}.yaml" \
  >"${schema_dir}/gatewayclass-v1.json"
yq --output-format=json \
  '.spec.versions[] | select(.name == "v2") | .schema.openAPIV3Schema' \
  "${cache_dir}/cilium-load-balancer-ip-pool-crd.yaml" \
  >"${schema_dir}/ciliumloadbalancerippool-v2.json"
yq --output-format=json \
  '.spec.versions[] | select(.name == "v2alpha1") | .schema.openAPIV3Schema' \
  "${cache_dir}/cilium-l2-announcement-policy-crd.yaml" \
  >"${schema_dir}/ciliuml2announcementpolicy-v2alpha1.json"

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/cilium/configure-cilium.yaml" \
  >"${validation_dir}/cilium-values-first.yaml"
"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/cilium/configure-cilium.yaml" \
  >"${validation_dir}/cilium-values-second.yaml"
cmp "${validation_dir}/cilium-values-first.yaml" \
  "${validation_dir}/cilium-values-second.yaml"

helm lint "${cache_dir}/cilium" \
  --values "${validation_dir}/cilium-values-first.yaml"
helm template cilium "${cache_dir}/cilium" \
  --namespace kube-system \
  --include-crds \
  --values "${validation_dir}/cilium-values-first.yaml" \
  >"${validation_dir}/cilium-render-first.yaml"
helm template cilium "${cache_dir}/cilium" \
  --namespace kube-system \
  --include-crds \
  --values "${validation_dir}/cilium-values-second.yaml" \
  >"${validation_dir}/cilium-render-second.yaml"
cmp "${validation_dir}/cilium-render-first.yaml" \
  "${validation_dir}/cilium-render-second.yaml"

kubeconform -strict -summary \
  -kubernetes-version 1.36.5 \
  -schema-location default \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  "${validation_dir}/cilium-render-first.yaml"

kustomize build "${repository_root}/platform/cilium/resources" | \
  "${repository_root}/scripts/render-config.sh" - \
  >"${validation_dir}/cilium-resources-first.yaml"
kustomize build "${repository_root}/platform/cilium/resources" | \
  "${repository_root}/scripts/render-config.sh" - \
  >"${validation_dir}/cilium-resources-second.yaml"
cmp "${validation_dir}/cilium-resources-first.yaml" \
  "${validation_dir}/cilium-resources-second.yaml"

lb_start="$(yq --unwrapScalar \
  'select(.kind == "CiliumLoadBalancerIPPool") | .spec.blocks[0].start' \
  "${validation_dir}/cilium-resources-first.yaml")"
lb_stop="$(yq --unwrapScalar \
  'select(.kind == "CiliumLoadBalancerIPPool") | .spec.blocks[0].stop' \
  "${validation_dir}/cilium-resources-first.yaml")"
test -n "${lb_start}" && test "${lb_start}" != null
test -n "${lb_stop}" && test "${lb_stop}" != null
test "$(yq --unwrapScalar \
  'select(.kind == "CiliumL2AnnouncementPolicy") | .apiVersion' \
  "${validation_dir}/cilium-resources-first.yaml")" = cilium.io/v2alpha1
test "$(yq --unwrapScalar \
  'select(.kind == "CiliumL2AnnouncementPolicy") | .spec.loadBalancerIPs' \
  "${validation_dir}/cilium-resources-first.yaml")" = true
test "$(yq --unwrapScalar \
  'select(.kind == "CiliumL2AnnouncementPolicy") | .spec.interfaces | length' \
  "${validation_dir}/cilium-resources-first.yaml")" = 1

kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  "${validation_dir}/cilium-resources-first.yaml"
kube-linter lint "${repository_root}/platform/network-policies/components/default-deny"/*.yaml

printf 'Cilium chart and network resources rendered deterministically.\n'
