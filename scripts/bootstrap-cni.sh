#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/cilium"
cilium_enable_l2_announcements="${CILIUM_ENABLE_L2_ANNOUNCEMENTS:-true}"

if [[ "${cilium_enable_l2_announcements}" != true && \
  "${cilium_enable_l2_announcements}" != false ]]; then
  printf 'CILIUM_ENABLE_L2_ANNOUNCEMENTS must be true or false.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${repository_root}/platform/cilium/dependencies.env"

"${repository_root}/scripts/check-config-ready.sh"
"${repository_root}/scripts/fetch-cilium-dependencies.sh"

gateway_file="${cache_dir}/gateway-api-standard-${GATEWAY_API_VERSION}.yaml"
kubectl apply --server-side --field-manager=homelab-bootstrap \
  --filename "${gateway_file}"
kubectl wait --for=condition=Established --timeout=120s \
  customresourcedefinition/gatewayclasses.gateway.networking.k8s.io \
  customresourcedefinition/gateways.gateway.networking.k8s.io \
  customresourcedefinition/httproutes.gateway.networking.k8s.io

helm_arguments=(
  upgrade
  --install
  cilium
  "${CILIUM_CHART_REF}"
  --namespace
  kube-system
  --values
  /dev/stdin
  --wait
  --timeout
  15m
)
if [[ "${cilium_enable_l2_announcements}" == false ]]; then
  helm_arguments+=(--set l2announcements.enabled=false)
fi

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/cilium/configure-cilium.yaml" | \
  helm "${helm_arguments[@]}"

if [[ "${cilium_enable_l2_announcements}" == true ]]; then
  kustomize build "${repository_root}/platform/cilium/resources" | \
    "${repository_root}/scripts/render-config.sh" - | \
    kubectl apply --server-side --field-manager=homelab-bootstrap --filename -
else
  printf 'Skipped LAN-only LB IPAM and L2 announcement resources.\n'
fi

kubectl --namespace kube-system rollout status daemonset/cilium --timeout=10m
kubectl --namespace kube-system rollout status deployment/cilium-operator --timeout=10m
