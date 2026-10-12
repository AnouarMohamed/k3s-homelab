#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cache_dir="${repository_root}/.cache/phase6"

# shellcheck disable=SC1091
source "${repository_root}/platform/openbao/dependencies.env"
# shellcheck disable=SC1091
source "${repository_root}/platform/external-secrets/dependencies.env"

mkdir -p "${cache_dir}"

fetch_chart() {
  local name="$1"
  local url="$2"
  local checksum="$3"
  local archive="${cache_dir}/${name}.tgz"

  curl --fail --location --silent --show-error "${url}" --output "${archive}"
  printf '%s  %s\n' "${checksum}" "${archive}" | sha256sum --check
  rm -rf "${cache_dir:?}/${name}"
  mkdir -p "${cache_dir}/${name}"
  tar -xzf "${archive}" --strip-components=1 -C "${cache_dir}/${name}"
}

fetch_chart openbao "${OPENBAO_CHART_URL}" "${OPENBAO_CHART_SHA256}"
fetch_chart external-secrets \
  "${EXTERNAL_SECRETS_CHART_URL}" "${EXTERNAL_SECRETS_CHART_SHA256}"

printf 'Cached verified Phase 6 dependencies in %s\n' "${cache_dir}"
