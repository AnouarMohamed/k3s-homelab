#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${repository_root}/.tools/bin:${PATH}"

for command_name in tofu yq; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'Required command is unavailable: %s\n' "${command_name}" >&2
    exit 1
  fi
done

"${repository_root}/scripts/check-config-ready.sh"

: "${AWS_ACCESS_KEY_ID:?Set AWS_ACCESS_KEY_ID for the S3-compatible state backend}"
: "${AWS_SECRET_ACCESS_KEY:?Set AWS_SECRET_ACCESS_KEY for the S3-compatible state backend}"

config_file="${repository_root}/config/homelab.yaml"
state_endpoint="$(yq -er '.spec.s3.endpoint' "${config_file}")"
state_bucket="$(yq -er '.spec.s3.bucket' "${config_file}")"

export AWS_ENDPOINT_URL_S3="${state_endpoint}"
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_EC2_METADATA_DISABLED=true

tofu -chdir="${repository_root}/infra/tofu" init -reconfigure \
  -backend-config="bucket=${state_bucket}" \
  -backend-config='key=homelab/cloudflare.tfstate' \
  -backend-config="region=${AWS_REGION}" \
  -backend-config='encrypt=true' \
  -backend-config='use_lockfile=true' \
  -backend-config='use_path_style=true' \
  -backend-config='skip_credentials_validation=true' \
  -backend-config='skip_region_validation=true' \
  -backend-config='skip_requesting_account_id=true' \
  -backend-config='skip_metadata_api_check=true'
