#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/phase3"

# shellcheck disable=SC1091
source "${repository_root}/platform/argocd/dependencies.env"

mkdir -p "${cache_dir}"
chart_digest="${ARGOCD_CHART_REF##*@sha256:}"
archive="${cache_dir}/argo-cd@sha256-${chart_digest}.tgz"
if [[ ! -f "${archive}" ]]; then
  helm pull "${ARGOCD_CHART_REF}" --destination "${cache_dir}"
fi

tar --extract --gzip --file "${archive}" --directory "${cache_dir}"
test "$(yq --unwrapScalar '.version' "${cache_dir}/argo-cd/Chart.yaml")" = \
  "${ARGOCD_CHART_VERSION}"
test "$(yq --unwrapScalar '.appVersion' "${cache_dir}/argo-cd/Chart.yaml")" = v3.5.4

printf 'Cached verified Phase 3 dependencies in %s\n' "${cache_dir}"
