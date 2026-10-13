#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"

verify_image() {
  local dependency_file="$1"
  local image_variable="$2"
  local version_variable="$3"
  local image version reference expected observed inspection
  # shellcheck disable=SC1090
  source "${dependency_file}"
  image="${!image_variable}"
  version="${!version_variable}"
  reference="${image%@sha256:*}"
  expected="sha256:${image##*@sha256:}"
  [[ "${reference}" == *":${version}"* || "${reference}" == *":v${version}"* || "${reference}" == *":${version}-rootless"* || "${reference}" == *":${version}-alpine"* ]]
  inspection="$(docker buildx imagetools inspect "${reference}")"
  observed="$(awk '$1 == "Digest:" {print $2; exit}' <<<"${inspection}")"
  test "${observed}" = "${expected}"
  printf 'Verified %s at %s.\n' "${reference}" "${observed}"
}

verify_image "${repository_root}/platform/keycloak/dependencies.env" KEYCLOAK_IMAGE KEYCLOAK_VERSION
verify_image "${repository_root}/apps/vaultwarden/dependencies.env" VAULTWARDEN_IMAGE VAULTWARDEN_VERSION
verify_image "${repository_root}/apps/homepage/dependencies.env" HOMEPAGE_IMAGE HOMEPAGE_VERSION
verify_image "${repository_root}/apps/uptime-kuma/dependencies.env" UPTIME_KUMA_IMAGE UPTIME_KUMA_VERSION
