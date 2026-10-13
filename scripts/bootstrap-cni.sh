#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/cilium"

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

helm upgrade --install cilium "${CILIUM_CHART_REF}" \
  --namespace kube-system \
  --values <("${repository_root}/scripts/render-config.sh" \
    "${repository_root}/platform/cilium/configure-cilium.yaml") \
  --wait \
  --timeout 15m

kustomize build "${repository_root}/platform/cilium/resources" | \
  "${repository_root}/scripts/render-config.sh" - | \
  kubectl apply --server-side --field-manager=homelab-bootstrap --filename -

kubectl --namespace kube-system rollout status daemonset/cilium --timeout=10m
kubectl --namespace kube-system rollout status deployment/cilium-operator --timeout=10m
