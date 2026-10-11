#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/phase2"

# shellcheck disable=SC1091
source "${repository_root}/platform/cilium/dependencies.env"

mkdir -p "${cache_dir}"

if [[ ! -f "${cache_dir}/cilium-${CILIUM_VERSION}.tgz" ]]; then
  helm pull "${CILIUM_CHART_REF}" --destination "${cache_dir}"
fi
tar --extract --gzip --file "${cache_dir}/cilium-${CILIUM_VERSION}.tgz" \
  --directory "${cache_dir}"

gateway_file="${cache_dir}/gateway-api-standard-${GATEWAY_API_VERSION}.yaml"
if [[ ! -f "${gateway_file}" ]]; then
  curl --fail --location --silent --show-error \
    --output "${gateway_file}" \
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
fi
printf '%s  %s\n' "${GATEWAY_API_SHA256}" "${gateway_file}" | sha256sum --check --strict

lb_crd="${cache_dir}/cilium-load-balancer-ip-pool-crd.yaml"
if [[ ! -f "${lb_crd}" ]]; then
  curl --fail --location --silent --show-error \
    --output "${lb_crd}" \
    "https://raw.githubusercontent.com/cilium/cilium/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
fi
printf '%s  %s\n' "${CILIUM_LB_CRD_SHA256}" "${lb_crd}" | sha256sum --check --strict

l2_crd="${cache_dir}/cilium-l2-announcement-policy-crd.yaml"
if [[ ! -f "${l2_crd}" ]]; then
  curl --fail --location --silent --show-error \
    --output "${l2_crd}" \
    "https://raw.githubusercontent.com/cilium/cilium/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliuml2announcementpolicies.yaml"
fi
printf '%s  %s\n' "${CILIUM_L2_CRD_SHA256}" "${l2_crd}" | sha256sum --check --strict

network_policy_crd="${cache_dir}/cilium-network-policy-crd.yaml"
if [[ ! -f "${network_policy_crd}" ]]; then
  curl --fail --location --silent --show-error \
    --output "${network_policy_crd}" \
    "https://raw.githubusercontent.com/cilium/cilium/v${CILIUM_VERSION}/pkg/k8s/apis/cilium.io/client/crds/v2/ciliumnetworkpolicies.yaml"
fi
printf '%s  %s\n' "${CILIUM_NETWORK_POLICY_CRD_SHA256}" "${network_policy_crd}" | \
  sha256sum --check --strict

test "$(yq --unwrapScalar '.version' "${cache_dir}/cilium/Chart.yaml")" = "${CILIUM_VERSION}"
printf 'Cached verified Phase 2 dependencies in %s\n' "${cache_dir}"
