#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${HOME}/.local/bin:${PATH}"
runtime_directory="${repository_root}/.runtime/aws-validation"
runtime_variables="${runtime_directory}/validation.auto.tfvars.json"

: "${AWS_VALIDATION_AMI_ID:?Set AWS_VALIDATION_AMI_ID to a pinned Ubuntu 24.04 amd64 AMI ID.}"
: "${AWS_VALIDATION_EXPIRES_AT:?Set AWS_VALIDATION_EXPIRES_AT to an RFC3339 time no more than seven days away.}"
: "${AWS_VALIDATION_SSH_PUBLIC_KEY_FILE:?Set AWS_VALIDATION_SSH_PUBLIC_KEY_FILE to an ephemeral Ed25519 public key.}"

if [[ ! -f "${AWS_VALIDATION_SSH_PUBLIC_KEY_FILE}" ]]; then
  printf 'Ephemeral SSH public key file does not exist: %s\n' \
    "${AWS_VALIDATION_SSH_PUBLIC_KEY_FILE}" >&2
  exit 1
fi

if ! grep -Eq '^(ssh-ed25519|sk-ssh-ed25519@openssh.com) ' \
  "${AWS_VALIDATION_SSH_PUBLIC_KEY_FILE}"; then
  printf 'AWS validation requires an Ed25519 public key.\n' >&2
  exit 1
fi

now_epoch="$(date --utc +%s)"
expires_epoch="$(date --utc --date="${AWS_VALIDATION_EXPIRES_AT}" +%s)"
maximum_epoch="$((now_epoch + 7 * 24 * 60 * 60))"
if (( expires_epoch <= now_epoch || expires_epoch > maximum_epoch )); then
  printf 'AWS_VALIDATION_EXPIRES_AT must be in the future and no more than seven days away.\n' >&2
  exit 1
fi

export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
export TF_VAR_aws_region="${AWS_REGION}"
export TF_VAR_availability_zone="${AWS_VALIDATION_AVAILABILITY_ZONE:-${AWS_REGION}a}"
export TF_VAR_expires_at="${AWS_VALIDATION_EXPIRES_AT}"
export TF_VAR_ssh_public_key
export TF_VAR_ubuntu_ami_id="${AWS_VALIDATION_AMI_ID}"
TF_VAR_ssh_public_key="$(<"${AWS_VALIDATION_SSH_PUBLIC_KEY_FILE}")"

aws sts get-caller-identity --output json >/dev/null

install -d -m 0700 "${runtime_directory}"
temporary_variables="${runtime_variables}.tmp"
jq -n \
  --arg aws_region "${AWS_REGION}" \
  --arg availability_zone "${TF_VAR_availability_zone}" \
  --arg expires_at "${TF_VAR_expires_at}" \
  --arg ssh_public_key "${TF_VAR_ssh_public_key}" \
  --arg ubuntu_ami_id "${TF_VAR_ubuntu_ami_id}" \
  '{
    aws_region: $aws_region,
    availability_zone: $availability_zone,
    expires_at: $expires_at,
    ssh_public_key: $ssh_public_key,
    ubuntu_ami_id: $ubuntu_ami_id
  }' >"${temporary_variables}"
chmod 0600 "${temporary_variables}"
mv "${temporary_variables}" "${runtime_variables}"

printf 'AWS validation inputs accepted for profile %s in %s; expiry is %s.\n' \
  "${AWS_PROFILE}" "${AWS_REGION}" "${AWS_VALIDATION_EXPIRES_AT}"
