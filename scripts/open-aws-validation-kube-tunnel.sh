#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
local_port="${AWS_VALIDATION_KUBE_PORT:-16443}"

if ! [[ "${local_port}" =~ ^[0-9]+$ ]] || \
  ((local_port < 1024 || local_port > 65535)); then
  printf 'AWS_VALIDATION_KUBE_PORT must be an unprivileged TCP port.\n' >&2
  exit 1
fi

aws sts get-caller-identity --output json >/dev/null
target="$(
  tofu -chdir="${repository_root}/infra/tofu/aws-validation" \
    output -json instance_ids | jq -r '."pc-1"'
)"
if [[ ! "${target}" =~ ^i-[0-9a-f]+$ ]]; then
  printf 'OpenTofu did not return the pc-1 EC2 instance ID.\n' >&2
  exit 1
fi

printf 'Opening Kubernetes API tunnel on https://127.0.0.1:%s; keep this terminal open.\n' \
  "${local_port}"
exec aws ssm start-session \
  --target "${target}" \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=6443,localPortNumber=${local_port}"
