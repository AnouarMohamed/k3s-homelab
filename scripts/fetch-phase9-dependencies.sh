#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
cache_dir="${repository_root}/.cache/phase9"
# shellcheck disable=SC1091
source "${repository_root}/platform/argo-rollouts/dependencies.env"

mkdir -p "${cache_dir}"
archive="${cache_dir}/argo-rollouts.tgz"
helm pull "${ARGO_ROLLOUTS_CHART_REF}" \
  --version "${ARGO_ROLLOUTS_CHART_VERSION}" \
  --destination "${cache_dir}"
mv "${cache_dir}/argo-rollouts-${ARGO_ROLLOUTS_CHART_VERSION}.tgz" "${archive}"
printf '%s  %s\n' "${ARGO_ROLLOUTS_CHART_SHA256}" "${archive}" | sha256sum --check
rm -rf "${cache_dir:?}/argo-rollouts"
mkdir -p "${cache_dir}/argo-rollouts"
tar --extract --gzip --file "${archive}" --strip-components=1 \
  --directory "${cache_dir}/argo-rollouts"

printf 'Cached verified Phase 9 dependencies in %s\n' "${cache_dir}"
