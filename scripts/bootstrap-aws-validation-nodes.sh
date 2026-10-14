#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${HOME}/.local/bin:${PATH}"
export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
runtime_directory="${repository_root}/.runtime/aws-validation"
private_key="${AWS_VALIDATION_SSH_PRIVATE_KEY_FILE:-${runtime_directory}/id_ed25519}"
token_file="${runtime_directory}/k3s-token"
inventory="${repository_root}/infra/ansible/inventory/aws_validation.py"

aws sts get-caller-identity --output json >/dev/null
test -x "${repository_root}/.tools/bin/session-manager-plugin"
if [[ ! -f "${private_key}" ]]; then
  printf 'Missing ephemeral SSH private key: %s\n' "${private_key}" >&2
  exit 1
fi

install -d -m 0700 "${runtime_directory}"
chmod 0600 "${private_key}"
mapfile -t instance_ids < <(
  tofu -chdir="${repository_root}/infra/tofu/aws-validation" \
    output -json instance_ids | jq -r 'to_entries | sort_by(.key)[] | .value'
)
if [[ "${#instance_ids[@]}" -ne 3 ]]; then
  printf 'Expected exactly three EC2 instance IDs from OpenTofu state.\n' >&2
  exit 1
fi

printf 'Waiting for all three nodes to register Online with Systems Manager...\n'
all_online=false
for _attempt in $(seq 1 60); do
  online_count=0
  for instance_id in "${instance_ids[@]}"; do
    ping_status="$(
      aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=${instance_id}" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text
    )"
    if [[ "${ping_status}" == Online ]]; then
      online_count="$((online_count + 1))"
    fi
  done
  if [[ "${online_count}" -eq 3 ]]; then
    all_online=true
    break
  fi
  sleep 10
done
if [[ "${all_online}" != true ]]; then
  printf 'Not all validation nodes became available through Systems Manager.\n' >&2
  exit 1
fi

if [[ ! -f "${token_file}" ]]; then
  umask 077
  openssl rand -hex 32 >"${token_file}"
fi
chmod 0600 "${token_file}"
export K3S_TOKEN
K3S_TOKEN="$(<"${token_file}")"
export K3S_S3_ACCESS_KEY=''
export K3S_S3_SECRET_KEY=''
export AWS_VALIDATION_SSH_PRIVATE_KEY_FILE="${private_key}"

ansible-inventory -i "${inventory}" --graph
ansible-playbook -i "${inventory}" "${repository_root}/infra/ansible/site.yaml"
