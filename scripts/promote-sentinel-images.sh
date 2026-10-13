#!/usr/bin/env bash
set -euo pipefail

environment="${1:-}"
api_digest="${2:-}"
worker_digest="${3:-}"
case "${environment}" in
  staging | prod) ;;
  *)
    printf 'Usage: %s <staging|prod> <api sha256 digest> <worker sha256 digest>\n' "$0" >&2
    exit 2
    ;;
esac
for digest in "${api_digest}" "${worker_digest}"; do
  if [[ ! "${digest}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
    printf 'Invalid image digest: %s\n' "${digest}" >&2
    exit 2
  fi
done

repository_root="$(git rev-parse --show-toplevel)"
lock_file="${repository_root}/apps/sentinel/overlays/${environment}/image-lock.env"
sed -i -E \
  "s#^(SENTINEL_API_IMAGE=.*@)sha256:[a-f0-9]{64}#\\1${api_digest}#" "${lock_file}"
sed -i -E \
  "s#^(SENTINEL_WORKER_IMAGE=.*@)sha256:[a-f0-9]{64}#\\1${worker_digest}#" "${lock_file}"

printf 'Pinned Sentinel %s to API %s and worker %s.\n' \
  "${environment}" "${api_digest}" "${worker_digest}"
