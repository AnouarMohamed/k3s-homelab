#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
export PATH="${repository_root}/.tools/bin:${PATH}"
config_file="${repository_root}/config/homelab.yaml"
input_file="${1:--}"

export CONFIG_DOMAIN
export CONFIG_ACME_EMAIL
export CONFIG_TIMEZONE
export CONFIG_GITLAB_PROJECT_PATH
export CONFIG_GITLAB_REPOSITORY_URL
export CONFIG_CONTROL_PLANE_VIP
export CONFIG_LOAD_BALANCER_START
export CONFIG_LOAD_BALANCER_STOP
export CONFIG_LONGHORN_DISK_PATH
export CONFIG_PRIVATE_ROUTE_CIDR
export CONFIG_NODE_INTERFACES
export CONFIG_NODE_INTERFACE_PATTERN
export CONFIG_S3_ENDPOINT
export CONFIG_S3_BUCKET
export CNPG_POSTGRES_IMAGE
export SNAPSHOT_CONTROLLER_IMAGE
export VELERO_AWS_PLUGIN_IMAGE

CONFIG_DOMAIN="$(yq --unwrapScalar '.spec.domain' "${config_file}")"
CONFIG_ACME_EMAIL="$(yq --unwrapScalar '.spec.acmeEmail' "${config_file}")"
CONFIG_TIMEZONE="$(yq --unwrapScalar '.spec.timezone' "${config_file}")"
CONFIG_GITLAB_PROJECT_PATH="$(yq --unwrapScalar '.spec.gitlab.projectPath' "${config_file}")"
CONFIG_GITLAB_REPOSITORY_URL="https://gitlab.com/${CONFIG_GITLAB_PROJECT_PATH}.git"
CONFIG_CONTROL_PLANE_VIP="$(yq --unwrapScalar '.spec.network.controlPlaneVip' "${config_file}")"
CONFIG_LOAD_BALANCER_START="$(yq --unwrapScalar '.spec.network.loadBalancerPool.start' "${config_file}")"
CONFIG_LOAD_BALANCER_STOP="$(yq --unwrapScalar '.spec.network.loadBalancerPool.stop' "${config_file}")"
CONFIG_LONGHORN_DISK_PATH="$(yq --unwrapScalar '.spec.storage.longhornDiskPath' "${config_file}")"
CONFIG_PRIVATE_ROUTE_CIDR="$(yq --unwrapScalar '.spec.network.privateRouteCidr' "${config_file}")"
CONFIG_NODE_INTERFACES="$(
  yq --unwrapScalar '.spec.network.nodes | map(.interface) | unique | join(",")' "${config_file}"
)"
CONFIG_NODE_INTERFACE_PATTERN="$(
  yq --unwrapScalar '.spec.network.nodes | map(.interface) | unique | "^(" + join("|") + ")$"' \
    "${config_file}"
)"
CONFIG_S3_ENDPOINT="$(yq --unwrapScalar '.spec.storage.s3.endpoint' "${config_file}")"
CONFIG_S3_BUCKET="$(yq --unwrapScalar '.spec.storage.s3.bucket' "${config_file}")"

yq '(
  .. |
  select(
    tag == "!!str" and
    test("\\$\\{(CONFIG_[A-Z0-9_]+|ARGOCD_IMAGE|KSOPS_IMAGE|YQ_IMAGE|CNPG_POSTGRES_IMAGE|SNAPSHOT_CONTROLLER_IMAGE|VELERO_AWS_PLUGIN_IMAGE)\\}")
  )
) |= envsubst(nu,ff) |
(
  select(
    .kind == "Secret" and
    .metadata.name == "gitlab-repository-credentials" and
    .metadata.namespace == "argocd"
  ).stringData.url
) = strenv(CONFIG_GITLAB_REPOSITORY_URL)' "${input_file}"
