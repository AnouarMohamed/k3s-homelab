#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
requested_path="${1:-${PWD}}"
source_path="$(cd "${requested_path}" && pwd -P)"

ensure_component_dependencies() {
  local component="$1"
  local marker
  local component_directory

  case "${component}" in
    cilium | argocd | edge | storage | secrets | observability | policy | sentinel | chaos) ;;
    *)
      printf 'Refusing unknown dependency component %s.\n' "${component}" >&2
      return 1
      ;;
  esac

  mkdir -p "${cache_root}"
  exec {cache_lock_fd}>"${cache_root}/.${component}.lock"
  flock "${cache_lock_fd}"
  marker="${cache_root}/${component}/.verified"
  component_directory="${cache_root}/${component}"
  if [[ ! -f "${marker}" ]]; then
    rm -rf -- "${component_directory}"
    HOMELAB_REPOSITORY_ROOT="${repository_root}" \
      HOMELAB_CACHE_ROOT="${cache_root}" \
      bash "${repository_root}/scripts/fetch-${component}-dependencies.sh" >&2
    touch "${marker}"
  fi
  flock --unlock "${cache_lock_fd}"
  exec {cache_lock_fd}>&-
}

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
    ensure_component_dependencies argocd
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/argocd/dependencies.env"
    set +a
    argocd_chart="${ARGOCD_CHART_REF}"
    if [[ -f "${cache_root}/argocd/argo-cd/Chart.yaml" ]]; then
      argocd_chart="${cache_root}/argocd/argo-cd"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/argocd/configure-argocd.yaml" | \
      helm template argocd "${argocd_chart}" \
        --kube-version 1.36.5 \
        --namespace argocd \
        --include-crds \
        --values -
    ;;
  platform/cilium)
    ensure_component_dependencies cilium
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cilium/dependencies.env"
    set +a
    cilium_chart="${CILIUM_CHART_REF}"
    if [[ -f "${cache_root}/cilium/cilium/Chart.yaml" ]]; then
      cilium_chart="${cache_root}/cilium/cilium"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/cilium/configure-cilium.yaml" | \
      helm template cilium "${cilium_chart}" \
        --kube-version 1.36.5 \
        --namespace kube-system \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cilium/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/cert-manager)
    ensure_component_dependencies edge
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cert-manager/dependencies.env"
    set +a
    cert_manager_chart="${CERT_MANAGER_CHART_REF}"
    if [[ -f "${cache_root}/edge/cert-manager/Chart.yaml" ]]; then
      cert_manager_chart="${cache_root}/edge/cert-manager"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/cert-manager/configure-cert-manager.yaml" | \
      helm template cert-manager "${cert_manager_chart}" \
        --kube-version 1.36.5 \
        --namespace cert-manager \
        --include-crds \
        --values - | \
      bash "${repository_root}/scripts/harden-cert-manager-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cert-manager/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/external-dns)
    ensure_component_dependencies edge
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/external-dns/dependencies.env"
    set +a
    external_dns_chart="${cache_root}/edge/external-dns"
    test -f "${external_dns_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/external-dns/configure-external-dns.yaml" | \
      helm template external-dns "${external_dns_chart}" \
        --kube-version 1.36.5 \
        --namespace external-dns \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/external-dns/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/snapshot-controller)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/snapshot-controller/dependencies.env"
    set +a
    kustomize build "${repository_root}/platform/snapshot-controller" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/longhorn)
    ensure_component_dependencies storage
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/longhorn/dependencies.env"
    set +a
    longhorn_chart="${cache_root}/storage/longhorn"
    test -f "${longhorn_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/longhorn/configure-longhorn.yaml" | \
      helm template longhorn "${longhorn_chart}" \
        --kube-version 1.36.5 \
        --namespace longhorn-system \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/longhorn/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/cloudnative-pg)
    ensure_component_dependencies storage
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cloudnative-pg/dependencies.env"
    set +a
    export CNPG_POSTGRES_IMAGE="${POSTGRES_IMAGE}"
    cnpg_chart="${cache_root}/storage/cloudnative-pg"
    barman_chart="${cache_root}/storage/plugin-barman-cloud"
    test -f "${cnpg_chart}/Chart.yaml"
    test -f "${barman_chart}/Chart.yaml"
    helm template cloudnative-pg "${cnpg_chart}" \
      --kube-version 1.36.5 \
      --namespace cnpg-system \
      --include-crds \
      --values "${repository_root}/platform/cloudnative-pg/configure-cloudnative-pg.yaml"
    printf '%s\n' '---'
    helm template barman-cloud "${barman_chart}" \
      --kube-version 1.36.5 \
      --namespace cnpg-system \
      --include-crds \
      --values "${repository_root}/platform/cloudnative-pg/configure-barman-cloud.yaml" | \
      bash "${repository_root}/scripts/harden-barman-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cloudnative-pg/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/velero)
    ensure_component_dependencies storage
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/velero/dependencies.env"
    set +a
    velero_chart="${cache_root}/storage/velero"
    test -f "${velero_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/velero/configure-velero.yaml" | \
      helm template velero "${velero_chart}" \
        --kube-version 1.36.5 \
        --namespace velero \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/velero/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/openbao)
    ensure_component_dependencies secrets
    openbao_chart="${cache_root}/secrets/openbao"
    test -f "${openbao_chart}/Chart.yaml"
    helm template openbao "${openbao_chart}" \
      --kube-version 1.36.5 \
      --namespace openbao \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/openbao/configure-openbao.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/openbao/resources"
    ;;
  platform/external-secrets)
    ensure_component_dependencies secrets
    external_secrets_chart="${cache_root}/secrets/external-secrets"
    test -f "${external_secrets_chart}/Chart.yaml"
    helm template external-secrets "${external_secrets_chart}" \
      --kube-version 1.36.5 \
      --namespace external-secrets \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/external-secrets/configure-external-secrets.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/prometheus-stack)
    ensure_component_dependencies observability
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/observability/prometheus-stack/configure-prometheus-stack.yaml" | \
    helm template monitoring "${cache_root}/observability/kube-prometheus-stack" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --include-crds \
      --skip-tests \
      --values - | \
      bash "${repository_root}/scripts/harden-observability-render.sh"
    ;;
  observability/blackbox)
    ensure_component_dependencies observability
    helm template blackbox "${cache_root}/observability/blackbox-exporter" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/blackbox/configure-blackbox-exporter.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/loki)
    ensure_component_dependencies observability
    helm template loki "${cache_root}/observability/loki" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/loki/configure-loki.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/alloy)
    ensure_component_dependencies observability
    helm template alloy "${cache_root}/observability/alloy" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/alloy/configure-alloy.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/tempo)
    ensure_component_dependencies observability
    helm template tempo "${cache_root}/observability/tempo" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/tempo/configure-tempo.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/otel-collector)
    ensure_component_dependencies observability
    helm template otel-collector "${cache_root}/observability/otel-collector" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/otel-collector/configure-otel-collector.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/sloth)
    ensure_component_dependencies observability
    helm template sloth "${cache_root}/observability/sloth" \
      --kube-version 1.36.5 \
      --namespace monitoring \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/observability/sloth/configure-sloth.yaml" | \
      bash "${repository_root}/scripts/harden-observability-render.sh"
    ;;
  policies/kyverno)
    ensure_component_dependencies policy
    helm template kyverno "${cache_root}/policy/kyverno" \
      --kube-version 1.36.5 \
      --namespace kyverno \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/policies/kyverno/configure-kyverno.yaml" | \
      bash "${repository_root}/scripts/harden-policy-render.sh"
    ;;
  policies/trivy)
    ensure_component_dependencies policy
    helm template trivy-operator "${cache_root}/policy/trivy-operator" \
      --kube-version 1.36.5 \
      --namespace trivy-system \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/policies/trivy/configure-trivy-operator.yaml"
    ;;
  platform/argo-rollouts)
    ensure_component_dependencies sentinel
    helm template argo-rollouts "${cache_root}/sentinel/argo-rollouts" \
      --kube-version 1.36.5 \
      --namespace argo-rollouts \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/argo-rollouts/configure-argo-rollouts.yaml"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/argo-rollouts/resources"
    ;;
  platform/chaos-mesh)
    ensure_component_dependencies chaos
    test -f "${cache_root}/chaos/chaos-mesh/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/chaos-mesh/configure-chaos-mesh.yaml" | \
      helm template chaos-mesh "${cache_root}/chaos/chaos-mesh" \
        --kube-version 1.36.5 \
        --namespace chaos-mesh \
        --include-crds \
        --skip-tests \
        --api-versions cert-manager.io/v1 \
        --values - | \
      bash "${repository_root}/scripts/harden-chaos-mesh-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/chaos-mesh/resources"
    ;;
  clusters/homelab/bootstrap | clusters/homelab/bootstrap/* | apps/*/overlays/prod | apps/*/overlays/staging | platform/* | observability/* | policies/*)
    test -f "${source_path}/kustomization.yaml" || test -f "${source_path}/kustomization.yml"
    kustomize build --enable-alpha-plugins --enable-exec "${source_path}" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  *)
    printf 'No approved GitOps renderer for %s.\n' "${relative_path}" >&2
    exit 1
    ;;
esac
