#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
runtime_variables="${repository_root}/.runtime/aws-validation/validation.auto.tfvars.json"

if [[ "${CONFIRM_AWS_DESTROY:-}" != homelab-validation ]]; then
  printf 'Refusing AWS destruction; set CONFIRM_AWS_DESTROY=homelab-validation after preserving evidence.\n' >&2
  exit 1
fi

if [[ ! -f "${runtime_variables}" ]]; then
  printf 'Missing retained AWS validation variables: %s\n' "${runtime_variables}" >&2
  exit 1
fi
aws sts get-caller-identity --output json >/dev/null

tofu -chdir="${repository_root}/infra/tofu/aws-validation" destroy \
  -input=false \
  -var-file="${runtime_variables}"
