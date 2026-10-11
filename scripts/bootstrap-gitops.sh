#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
credential_file="${repository_root}/clusters/homelab/bootstrap/provide-gitlab-repository-credentials.sops.yaml"
placeholder_recipient="age17mvgle6026gdpsflmnxtsmrflmwhe0h28kdwpp5jusqaha7f4ufsm2cle5"

"${repository_root}/scripts/check-config-ready.sh"
: "${SOPS_AGE_KEY_FILE:?Set SOPS_AGE_KEY_FILE to the Anouar age identity file.}"
test -f "${SOPS_AGE_KEY_FILE}"

case "$(cd "$(dirname "${SOPS_AGE_KEY_FILE}")" && pwd -P)/$(basename "${SOPS_AGE_KEY_FILE}")" in
  "${repository_root}"/*)
    printf 'The age identity must not be stored inside this public repository.\n' >&2
    exit 1
    ;;
esac

configured_recipient="$(yq --unwrapScalar '.creation_rules[0].age' "${repository_root}/.sops.yaml")"
identity_recipient="$(age-keygen -y "${SOPS_AGE_KEY_FILE}")"
test "${configured_recipient}" = "${identity_recipient}" || {
  printf 'The age identity does not match .sops.yaml; re-encrypt bootstrap secrets.\n' >&2
  exit 1
}
test "${configured_recipient}" != "${placeholder_recipient}" || {
  printf 'Replace the disposable age recipient and re-encrypt before bootstrap.\n' >&2
  exit 1
}

set -a
# shellcheck disable=SC1091
source "${repository_root}/platform/argocd/dependencies.env"
set +a
"${repository_root}/scripts/fetch-phase3-dependencies.sh"

kubectl create namespace argocd --dry-run=client --output=yaml | kubectl apply -f -
kubectl create secret generic sops-age \
  --namespace argocd \
  --from-file="keys.txt=${SOPS_AGE_KEY_FILE}" \
  --dry-run=client \
  --output=yaml | kubectl apply -f -

export CONFIG_GITLAB_REPOSITORY_URL
CONFIG_GITLAB_REPOSITORY_URL="$({
  yq --unwrapScalar '.spec.gitlab.projectPath' "${repository_root}/config/homelab.yaml"
} | sed 's#^#https://gitlab.com/#; s#$#.git#')"
sops --decrypt "${credential_file}" | \
  "${repository_root}/scripts/render-config.sh" - | \
  kubectl apply -f -

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/argocd/configure-argocd.yaml" | \
  helm upgrade --install argocd "${repository_root}/.cache/phase3/argo-cd" \
    --namespace argocd \
    --values - \
    --wait \
    --timeout 10m

kustomize build "${repository_root}/clusters/homelab/projects" | \
  "${repository_root}/scripts/render-config.sh" - | \
  kubectl apply -f -
"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/clusters/homelab/root-app.yaml" | \
  kubectl apply -f -

kubectl --namespace argocd rollout status deployment/argocd-server --timeout=5m
kubectl --namespace argocd rollout status deployment/argocd-repo-server --timeout=5m
printf 'Argo CD bootstrap applied; verify root synchronization before continuing.\n'
