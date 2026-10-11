#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
export PATH="${repository_root}/.tools/bin:${PATH}"
requested_path="${1:-${PWD}}"
source_path="$(cd "${requested_path}" && pwd -P)"

case "${source_path}" in
  "${repository_root}"/*) ;;
  *)
    printf 'Refusing to render a path outside the repository.\n' >&2
    exit 1
    ;;
esac

relative_path="${source_path#"${repository_root}/"}"

case "${relative_path}" in
  platform/argocd)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/argocd/dependencies.env"
    set +a
    argocd_chart="${ARGOCD_CHART_REF}"
    if [[ -f "${repository_root}/.cache/phase3/argo-cd/Chart.yaml" ]]; then
      argocd_chart="${repository_root}/.cache/phase3/argo-cd"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/argocd/configure-argocd.yaml" | \
      helm template argocd "${argocd_chart}" \
        --namespace argocd \
        --include-crds \
        --values -
    ;;
  platform/cilium)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cilium/dependencies.env"
    set +a
    cilium_chart="${CILIUM_CHART_REF}"
    if [[ -f "${repository_root}/.cache/phase2/cilium/Chart.yaml" ]]; then
      cilium_chart="${repository_root}/.cache/phase2/cilium"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/cilium/configure-cilium.yaml" | \
      helm template cilium "${cilium_chart}" \
        --namespace kube-system \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cilium/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/cert-manager)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cert-manager/dependencies.env"
    set +a
    cert_manager_chart="${CERT_MANAGER_CHART_REF}"
    if [[ -f "${repository_root}/.cache/phase4/cert-manager/Chart.yaml" ]]; then
      cert_manager_chart="${repository_root}/.cache/phase4/cert-manager"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/cert-manager/configure-cert-manager.yaml" | \
      helm template cert-manager "${cert_manager_chart}" \
        --namespace cert-manager \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cert-manager/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/external-dns)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/external-dns/dependencies.env"
    set +a
    external_dns_chart="${repository_root}/.cache/phase4/external-dns"
    test -f "${external_dns_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/external-dns/configure-external-dns.yaml" | \
      helm template external-dns "${external_dns_chart}" \
        --namespace external-dns \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/external-dns/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  clusters/homelab/bootstrap | clusters/homelab/bootstrap/* | apps/*/overlays/prod | platform/* | observability/* | policies/*)
    test -f "${source_path}/kustomization.yaml" || test -f "${source_path}/kustomization.yml"
    kustomize build --enable-alpha-plugins --enable-exec "${source_path}" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  *)
    printf 'No approved GitOps renderer for %s.\n' "${relative_path}" >&2
    exit 1
    ;;
esac
