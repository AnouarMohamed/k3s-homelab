#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
plan_file="${repository_root}/.cache/aws-validation/validation.tfplan"

if [[ "${CONFIRM_AWS_SPEND:-}" != 150 ]]; then
  printf 'Refusing AWS apply; set CONFIRM_AWS_SPEND=150 after reviewing the saved plan.\n' >&2
  exit 1
fi
if [[ ! -f "${plan_file}" ]]; then
  printf 'No saved AWS validation plan exists; run make aws-validation-plan first.\n' >&2
  exit 1
fi

# Recheck identity and the seven-day deadline immediately before apply.
# shellcheck disable=SC1091
source "${repository_root}/scripts/check-aws-validation-inputs.sh"

tofu -chdir="${repository_root}/infra/tofu/aws-validation" apply \
  -input=false \
  "${plan_file}"
