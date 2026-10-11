#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/phase4"

# shellcheck disable=SC1091
source "${repository_root}/platform/cert-manager/dependencies.env"
# shellcheck disable=SC1091
source "${repository_root}/platform/external-dns/dependencies.env"

mkdir -p "${cache_dir}"

cert_manager_digest="${CERT_MANAGER_CHART_REF##*@sha256:}"
cert_manager_archive="${cache_dir}/cert-manager@sha256-${cert_manager_digest}.tgz"
if [[ ! -f "${cert_manager_archive}" ]]; then
  helm pull "${CERT_MANAGER_CHART_REF}" --destination "${cache_dir}"
fi
tar --extract --gzip --file "${cert_manager_archive}" --directory "${cache_dir}"
test "$(yq --unwrapScalar '.version' "${cache_dir}/cert-manager/Chart.yaml")" = \
  "v${CERT_MANAGER_CHART_VERSION}"
test "$(yq --unwrapScalar '.appVersion' "${cache_dir}/cert-manager/Chart.yaml")" = \
  "v${CERT_MANAGER_CHART_VERSION}"

external_dns_archive="${cache_dir}/external-dns-${EXTERNAL_DNS_CHART_VERSION}.tgz"
if [[ ! -f "${external_dns_archive}" ]]; then
  curl --fail --location --silent --show-error \
    --output "${external_dns_archive}" "${EXTERNAL_DNS_CHART_URL}"
fi
printf '%s  %s\n' "${EXTERNAL_DNS_CHART_SHA256}" "${external_dns_archive}" | \
  sha256sum --check --strict
tar --extract --gzip --file "${external_dns_archive}" --directory "${cache_dir}"
test "$(yq --unwrapScalar '.version' "${cache_dir}/external-dns/Chart.yaml")" = \
  "${EXTERNAL_DNS_CHART_VERSION}"
test "$(yq --unwrapScalar '.appVersion' "${cache_dir}/external-dns/Chart.yaml")" = \
  "${EXTERNAL_DNS_APP_VERSION}"

printf 'Cached verified Phase 4 dependencies in %s\n' "${cache_dir}"
