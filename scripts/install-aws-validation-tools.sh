#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
tool_bin="${repository_root}/.tools/bin"
mkdir -p "${tool_bin}"

# shellcheck disable=SC1091
source "${repository_root}/infra/tofu/aws-validation/dependencies.env"

if [[ -x "${tool_bin}/session-manager-plugin" ]] && \
  [[ "$("${tool_bin}/session-manager-plugin" --version)" == "${SESSION_MANAGER_PLUGIN_VERSION}" ]]; then
  printf 'Session Manager plugin %s is already installed locally.\n' \
    "${SESSION_MANAGER_PLUGIN_VERSION}"
  exit 0
fi

download_directory="$(mktemp -d)"
trap 'rm -rf -- "${download_directory}"' EXIT
package="${download_directory}/session-manager-plugin.deb"

curl --fail --location --silent --show-error \
  --output "${package}" "${SESSION_MANAGER_PLUGIN_URL}"
printf '%s  %s\n' "${SESSION_MANAGER_PLUGIN_SHA256}" "${package}" | \
  sha256sum --check --strict
mkdir -p "${download_directory}/archive" "${download_directory}/package"
(
  cd "${download_directory}/archive"
  ar x "${package}"
)
data_archives=("${download_directory}"/archive/data.tar.*)
test "${#data_archives[@]}" = 1
tar --extract --file "${data_archives[0]}" \
  --directory "${download_directory}/package"
install -m 0755 \
  "${download_directory}/package/usr/local/sessionmanagerplugin/bin/session-manager-plugin" \
  "${tool_bin}/session-manager-plugin"

test "$("${tool_bin}/session-manager-plugin" --version)" = \
  "${SESSION_MANAGER_PLUGIN_VERSION}"
printf 'Installed Session Manager plugin %s into %s.\n' \
  "${SESSION_MANAGER_PLUGIN_VERSION}" "${tool_bin}"
