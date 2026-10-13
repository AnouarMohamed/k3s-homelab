#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
cache_dir="${cache_root}/phase11"
mkdir -p "${cache_dir}"

# shellcheck disable=SC1091
source "${repository_root}/platform/chaos-mesh/dependencies.env"

archive="${cache_dir}/chaos-mesh-${CHAOS_MESH_CHART_VERSION}.tgz"
curl --fail --silent --show-error --location "${CHAOS_MESH_CHART_URL}" --output "${archive}"
printf '%s  %s\n' "${CHAOS_MESH_CHART_SHA256}" "${archive}" | sha256sum --check
rm -rf -- "${cache_dir}/chaos-mesh"
mkdir -p "${cache_dir}/chaos-mesh"
tar -xzf "${archive}" --strip-components=1 -C "${cache_dir}/chaos-mesh"

test "$(yq --unwrapScalar '.version' "${cache_dir}/chaos-mesh/Chart.yaml")" = "${CHAOS_MESH_CHART_VERSION}"
test "$(yq --unwrapScalar '.appVersion' "${cache_dir}/chaos-mesh/Chart.yaml")" = "${CHAOS_MESH_APP_VERSION}"
printf 'Cached verified Phase 11 dependency in %s.\n' "${cache_dir}"
