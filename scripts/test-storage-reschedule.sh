#!/usr/bin/env bash
set -euo pipefail

if [[ "${CONFIRM_STORAGE_TEST:-}" != homelab ]]; then
  printf 'Refusing storage test; use CONFIRM_STORAGE_TEST=homelab after reading the runbook.\n' >&2
  exit 1
fi

namespace=storage-verification
deployment=storage-reschedule-verification
selector=app.kubernetes.io/name=storage-reschedule-verification
marker="storage-reschedule-$(date -u +%Y%m%dT%H%M%SZ)"

kubectl -n "${namespace}" rollout status "deployment/${deployment}" --timeout=5m
old_pod="$(kubectl -n "${namespace}" get pod -l "${selector}" -o jsonpath='{.items[0].metadata.name}')"
old_node="$(kubectl -n "${namespace}" get pod "${old_pod}" -o jsonpath='{.spec.nodeName}')"

# The positional parameter expands in the container shell.
# shellcheck disable=SC2016
kubectl -n "${namespace}" exec "${old_pod}" -- \
  sh -c 'printf "%s\n" "$1" > /data/marker' sh "${marker}"
test "$(kubectl -n "${namespace}" exec "${old_pod}" -- cat /data/marker)" = "${marker}"

uncordon_node() {
  kubectl uncordon "${old_node}" >/dev/null 2>&1 || true
}
trap uncordon_node EXIT

kubectl cordon "${old_node}"
kubectl -n "${namespace}" delete pod "${old_pod}" --wait=true
kubectl -n "${namespace}" rollout status "deployment/${deployment}" --timeout=10m

new_pod="$(kubectl -n "${namespace}" get pod -l "${selector}" -o jsonpath='{.items[0].metadata.name}')"
new_node="$(kubectl -n "${namespace}" get pod "${new_pod}" -o jsonpath='{.spec.nodeName}')"
test "${new_node}" != "${old_node}"
test "$(kubectl -n "${namespace}" exec "${new_pod}" -- cat /data/marker)" = "${marker}"

uncordon_node
trap - EXIT
printf 'Marker survived a pod move from %s to %s. Record the observation in the hardware ledger.\n' \
  "${old_node}" "${new_node}"
