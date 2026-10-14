#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${HOME}/.local/bin:${PATH}"
export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
runtime_directory="${repository_root}/.runtime/aws-validation"
private_key="${AWS_VALIDATION_SSH_PRIVATE_KEY_FILE:-${runtime_directory}/id_ed25519}"
inventory="${repository_root}/infra/ansible/inventory/aws_validation.py"
kubeconfig="${runtime_directory}/kubeconfig"

aws sts get-caller-identity --output json >/dev/null
test -x "${repository_root}/.tools/bin/session-manager-plugin"
if [[ ! -f "${private_key}" ]]; then
  printf 'Missing ephemeral SSH private key: %s\n' "${private_key}" >&2
  exit 1
fi

install -d -m 0700 "${runtime_directory}"
export AWS_VALIDATION_SSH_PRIVATE_KEY_FILE="${private_key}"
ansible initial_server -i "${inventory}" --become \
  --module-name ansible.builtin.fetch \
  --args "src=/etc/rancher/k3s/k3s.yaml dest=${kubeconfig} flat=yes"
chmod 0600 "${kubeconfig}"
sed -i -E \
  's#^([[:space:]]*server:)[[:space:]]+https://[^:]+:6443#\1 https://127.0.0.1:16443#' \
  "${kubeconfig}"
if ! grep -Eq '^[[:space:]]*server: https://127\.0\.0\.1:16443$' "${kubeconfig}"; then
  printf 'The generated kubeconfig does not target the local SSM tunnel.\n' >&2
  exit 1
fi

printf 'Wrote the ignored kubeconfig to %s.\n' "${kubeconfig}"
