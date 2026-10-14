#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

# shellcheck disable=SC1091
source "${repository_root}/scripts/check-aws-validation-inputs.sh"

plan_directory="${repository_root}/.cache/aws-validation"
runtime_variables="${repository_root}/.runtime/aws-validation/validation.auto.tfvars.json"
mkdir -p "${plan_directory}"

tofu -chdir="${repository_root}/infra/tofu/aws-validation" fmt -check
tofu -chdir="${repository_root}/infra/tofu/aws-validation" validate
tofu -chdir="${repository_root}/infra/tofu/aws-validation" plan \
  -input=false \
  -var-file="${runtime_variables}" \
  -out="${plan_directory}/validation.tfplan"

printf 'Saved the reviewed-plan candidate to %s. No resources were created.\n' \
  "${plan_directory}/validation.tfplan"
