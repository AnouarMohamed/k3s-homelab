#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
namespace=argocd
root_application=homelab-root
timeout_seconds="${ARGOCD_BOOTSTRAP_TIMEOUT_SECONDS:-1800}"
poll_seconds=10

if ! [[ "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]]; then
  printf 'ARGOCD_BOOTSTRAP_TIMEOUT_SECONDS must be a positive integer.\n' >&2
  exit 1
fi

kubectl --namespace "${namespace}" get application "${root_application}" >/dev/null
kubectl --namespace "${namespace}" annotate application "${root_application}" \
  argocd.argoproj.io/refresh=hard --overwrite >/dev/null

deadline=$((SECONDS + timeout_seconds))
while ((SECONDS < deadline)); do
  application_table="$({
    kubectl --namespace "${namespace}" get applications \
      --output=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\t"}{.status.health.status}{"\t"}{.status.operationState.phase}{"\n"}{end}'
  })"

  application_count="$(printf '%s\n' "${application_table}" | awk 'NF { count++ } END { print count + 0 }')"
  failed_applications="$(
    printf '%s\n' "${application_table}" |
      awk -F '\t' '$4 == "Error" || $4 == "Failed" { print $1 ":" $4 }'
  )"
  if [[ -n "${failed_applications}" ]]; then
    printf 'Argo CD reported a failed synchronization:\n%s\n' "${failed_applications}" >&2
    exit 1
  fi

  unsettled_applications="$(
    printf '%s\n' "${application_table}" |
      awk -F '\t' '$2 != "Synced" || $3 != "Healthy" { print $1 ":sync=" $2 ",health=" $3 }'
  )"
  if ((application_count > 1)) && [[ -z "${unsettled_applications}" ]]; then
    printf 'Argo CD reports %s applications Synced and Healthy.\n' "${application_count}"
    exit 0
  fi

  printf 'Waiting for Argo CD: %s application(s) discovered' "${application_count}"
  if [[ -n "${unsettled_applications}" ]]; then
    printf '; unsettled: %s' "$(printf '%s' "${unsettled_applications}" | paste -sd ', ' -)"
  fi
  printf '\n'
  sleep "${poll_seconds}"
done

printf 'Timed out after %s seconds waiting for every Argo CD application to become Synced and Healthy.\n' \
  "${timeout_seconds}" >&2
kubectl --namespace "${namespace}" get applications >&2
exit 1
