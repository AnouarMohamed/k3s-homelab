#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
cache_dir="${cache_root}/phase7"
# shellcheck disable=SC1091
source "${repository_root}/observability/dependencies.env"

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

fetch_chart kube-prometheus-stack "${KUBE_PROMETHEUS_STACK_CHART_URL}" \
  "${KUBE_PROMETHEUS_STACK_CHART_SHA256}"
fetch_chart blackbox-exporter "${BLACKBOX_EXPORTER_CHART_URL}" \
  "${BLACKBOX_EXPORTER_CHART_SHA256}"
fetch_chart loki "${LOKI_CHART_URL}" "${LOKI_CHART_SHA256}"
fetch_chart alloy "${ALLOY_CHART_URL}" "${ALLOY_CHART_SHA256}"
fetch_chart tempo "${TEMPO_CHART_URL}" "${TEMPO_CHART_SHA256}"
fetch_chart otel-collector "${OTEL_COLLECTOR_CHART_URL}" \
  "${OTEL_COLLECTOR_CHART_SHA256}"
fetch_chart sloth "${SLOTH_CHART_URL}" "${SLOTH_CHART_SHA256}"

printf 'Cached verified Phase 7 dependencies in %s\n' "${cache_dir}"
