#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
tool_root="${repository_root}/.tools"
tool_bin="${tool_root}/bin"

# repository_root is resolved dynamically, so ShellCheck cannot follow this file.
# shellcheck disable=SC1091
source "${repository_root}/scripts/tool-versions.env"

mkdir -p "${tool_bin}" "${tool_root}/npm"

download_dir="$(mktemp -d)"
trap 'rm -rf "${download_dir}"' EXIT

export GOBIN="${tool_bin}"
export GOTOOLCHAIN=local

install_go_tool() {
  local package="$1"
  local version="$2"
  printf 'Installing %s at %s\n' "${package}" "${version}"
  go install "${package}@${version}"
}

install_tar_binary() {
  local url="$1"
  local checksum_url="$2"
  local archive="$3"
  local binary="$4"

  printf 'Installing %s from signed release assets\n' "${binary}"
  curl --fail --location --silent --show-error --output "${download_dir}/${archive}" "${url}"
  curl --fail --location --silent --show-error \
    --output "${download_dir}/checksums.txt" "${checksum_url}"
  (
    cd "${download_dir}"
    grep "  ${archive}$" checksums.txt | sha256sum --check --strict
  )
  tar --extract --gzip --file "${download_dir}/${archive}" --directory "${download_dir}" "${binary}"
  install --mode 0755 "${download_dir}/${binary}" "${tool_bin}/${binary}"
  rm -f "${download_dir:?}/${archive}" "${download_dir}/checksums.txt" "${download_dir}/${binary}"
}

install_go_tool github.com/yannh/kubeconform/cmd/kubeconform "${KUBECONFORM_VERSION}"
install_go_tool golang.stackrox.io/kube-linter/cmd/kube-linter "${KUBE_LINTER_VERSION}"
install_go_tool go.k6.io/k6 "${K6_VERSION}"
install_go_tool github.com/zricethezav/gitleaks/v8 "${GITLEAKS_VERSION}"
install_tar_binary \
  "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz" \
  "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/checksums.txt" \
  "kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz" \
  kyverno
install_go_tool sigs.k8s.io/kustomize/kustomize/v5 "${KUSTOMIZE_VERSION}"
install_go_tool filippo.io/age/cmd/age "${AGE_VERSION}"
install_go_tool filippo.io/age/cmd/age-keygen "${AGE_VERSION}"
install_go_tool github.com/mikefarah/yq/v4 "${YQ_VERSION}"
install_go_tool github.com/getsops/sops/v3/cmd/sops "${SOPS_VERSION}"
tofu_release="${TOFU_VERSION#v}"
install_tar_binary \
  "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/tofu_${tofu_release}_linux_amd64.tar.gz" \
  "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/tofu_${tofu_release}_SHA256SUMS" \
  "tofu_${tofu_release}_linux_amd64.tar.gz" \
  tofu
prometheus_archive="prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
prometheus_directory="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
curl --fail --location --silent --show-error \
  --output "${download_dir}/${prometheus_archive}" \
  "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${prometheus_archive}"
curl --fail --location --silent --show-error \
  --output "${download_dir}/prometheus-sha256sums.txt" \
  "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/sha256sums.txt"
(
  cd "${download_dir}"
  grep "  ${prometheus_archive}$" prometheus-sha256sums.txt | sha256sum --check --strict
)
tar --extract --gzip \
  --file "${download_dir}/${prometheus_archive}" \
  --directory "${download_dir}" \
  "${prometheus_directory}/promtool"
install --mode 0755 \
  "${download_dir}/${prometheus_directory}/promtool" \
  "${tool_bin}/promtool"
rm -rf \
  "${download_dir:?}/${prometheus_archive}" \
  "${download_dir}/prometheus-sha256sums.txt" \
  "${download_dir:?}/${prometheus_directory}"

shellcheck_archive="shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
shellcheck_directory="shellcheck-v${SHELLCHECK_VERSION}"
curl --fail --location --silent --show-error \
  --output "${download_dir}/${shellcheck_archive}" \
  "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/${shellcheck_archive}"
(
  cd "${download_dir}"
  printf '%s  %s\n' "${SHELLCHECK_SHA256}" "${shellcheck_archive}" | \
    sha256sum --check --strict
)
tar --extract --xz \
  --file "${download_dir}/${shellcheck_archive}" \
  --directory "${download_dir}" \
  "${shellcheck_directory}/shellcheck"
install --mode 0755 \
  "${download_dir}/${shellcheck_directory}/shellcheck" \
  "${tool_bin}/shellcheck"
rm -rf \
  "${download_dir:?}/${shellcheck_archive}" \
  "${download_dir:?}/${shellcheck_directory}"

npm install \
  --no-audit \
  --no-fund \
  --prefix "${tool_root}/npm" \
  "markdownlint-cli2@${MARKDOWNLINT_VERSION}"

ln -sfn "${tool_root}/npm/node_modules/.bin/markdownlint-cli2" "${tool_bin}/markdownlint-cli2"

printf 'Installed tools in %s\n' "${tool_bin}"
