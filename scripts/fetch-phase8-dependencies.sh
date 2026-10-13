#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
cache_dir="${cache_root}/phase8"
# shellcheck disable=SC1091
source "${repository_root}/policies/dependencies.env"

mkdir -p "${cache_dir}"

fetch_chart() {
  local name="$1"
  local url="$2"
  local sha256="$3"
  local archive="${cache_dir}/${name}.tgz"

  curl --fail --location --silent --show-error \
    --retry 5 --retry-all-errors --connect-timeout 20 \
    "${url}" --output "${archive}"
  printf '%s  %s\n' "${sha256}" "${archive}" | sha256sum --check
  rm -rf "${cache_dir:?}/${name}"
  mkdir -p "${cache_dir}/${name}"
  tar --extract --gzip --file "${archive}" --strip-components=1 \
    --directory "${cache_dir}/${name}"
}

fetch_chart kyverno "${KYVERNO_CHART_URL}" "${KYVERNO_CHART_SHA256}"
fetch_chart trivy-operator "${TRIVY_OPERATOR_CHART_URL}" \
  "${TRIVY_OPERATOR_CHART_SHA256}"

printf 'Cached verified Phase 8 dependencies in %s\n' "${cache_dir}"
