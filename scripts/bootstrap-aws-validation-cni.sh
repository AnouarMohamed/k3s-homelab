#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
export KUBECONFIG="${repository_root}/.runtime/aws-validation/kubeconfig"

if [[ ! -f "${KUBECONFIG}" ]]; then
  printf 'Missing AWS validation kubeconfig; run make aws-validation-kubeconfig.\n' >&2
  exit 1
fi

export CONFIG_CONTROL_PLANE_ENDPOINT_OVERRIDE
CONFIG_CONTROL_PLANE_ENDPOINT_OVERRIDE="$(
  tofu -chdir="${repository_root}/infra/tofu/aws-validation" \
    output -raw control_plane_endpoint
)"
export CONFIG_NODE_INTERFACES_OVERRIDE=ens5
export CILIUM_ENABLE_L2_ANNOUNCEMENTS=false

kubectl get --raw=/readyz >/dev/null
"${repository_root}/scripts/bootstrap-cni.sh"
