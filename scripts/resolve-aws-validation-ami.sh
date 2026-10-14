#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
export AWS_PROFILE="${AWS_PROFILE:-homelab-aws}"
export AWS_REGION="${AWS_REGION:-eu-west-1}"

parameter_name='/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id'
canonical_owner_id='099720109477'

aws sts get-caller-identity --output json >/dev/null
ami_id="$(
  aws ssm get-parameter \
    --name "${parameter_name}" \
    --query 'Parameter.Value' \
    --output text
)"

image_summary="$(
  aws ec2 describe-images \
    --image-ids "${ami_id}" \
    --owners "${canonical_owner_id}" \
    --query 'Images[0].[ImageId,Architecture,RootDeviceType,State,Name]' \
    --output text
)"

read -r observed_id architecture root_device state image_name <<<"${image_summary}"
if [[ "${observed_id}" != "${ami_id}" || "${architecture}" != x86_64 || \
  "${root_device}" != ebs || "${state}" != available || \
  "${image_name}" != ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-* ]]; then
  printf 'Canonical AMI validation failed for %s: %s\n' \
    "${ami_id}" "${image_summary}" >&2
  exit 1
fi

printf 'Resolved Canonical Ubuntu image %s (%s). Review and export this immutable ID.\n' \
  "${ami_id}" "${image_name}" >&2
printf '%s\n' "${ami_id}"
