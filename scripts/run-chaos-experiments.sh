#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

if [[ "${CONFIRM_CHAOS:-}" != homelab ]]; then
  printf 'Refusing chaos experiments; use CONFIRM_CHAOS=homelab after reading the runbook.\n' >&2
  exit 1
fi

annotation="$(kubectl get namespace chaos-testing -o jsonpath='{.metadata.annotations.chaos-mesh\.org/inject}')"
test "${annotation}" = enabled || {
  printf 'chaos-testing is not the only explicitly enabled test namespace.\n' >&2
  exit 1
}

unexpected="$({ kubectl get namespaces -o json | yq --input-format=json -r '.items[] | select(.metadata.annotations."chaos-mesh.org/inject" == "enabled") | .metadata.name'; } | grep -v '^chaos-testing$' || true)"
test -z "${unexpected}" || {
  printf 'Refusing: another namespace enables Chaos Mesh injection: %s\n' "${unexpected}" >&2
  exit 1
}

kubectl apply --server-side --dry-run=server -k "${repository_root}/platform/chaos-mesh/experiments"
kubectl apply --server-side -k "${repository_root}/platform/chaos-mesh/experiments"
printf 'Experiments submitted only to chaos-testing. Monitor and delete them per the runbook.\n'
