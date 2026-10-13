#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
cache_dir="${cache_root}/phase5"

# shellcheck disable=SC1091
source "${repository_root}/platform/longhorn/dependencies.env"
# shellcheck disable=SC1091
source "${repository_root}/platform/cloudnative-pg/dependencies.env"
# shellcheck disable=SC1091
source "${repository_root}/platform/velero/dependencies.env"

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

fetch_chart longhorn "${LONGHORN_CHART_URL}" "${LONGHORN_CHART_SHA256}"
fetch_chart cloudnative-pg "${CNPG_CHART_URL}" "${CNPG_CHART_SHA256}"
fetch_chart plugin-barman-cloud "${BARMAN_CHART_URL}" "${BARMAN_CHART_SHA256}"
fetch_chart velero "${VELERO_CHART_URL}" "${VELERO_CHART_SHA256}"

printf 'Cached verified Phase 5 dependencies in %s\n' "${cache_dir}"
