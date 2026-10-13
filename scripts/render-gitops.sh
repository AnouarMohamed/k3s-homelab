#!/usr/bin/env bash
set -euo pipefail

repository_root="${HOMELAB_REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_root="${HOMELAB_CACHE_ROOT:-${repository_root}/.cache}"
requested_path="${1:-${PWD}}"
source_path="$(cd "${requested_path}" && pwd -P)"

ensure_phase_dependencies() {
  local phase="$1"
  local marker
  local phase_directory

  case "${phase}" in
    phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | phase8 | phase9 | phase11) ;;
    *)
      printf 'Refusing unknown dependency phase %s.\n' "${phase}" >&2
      return 1
      ;;
  esac

  mkdir -p "${cache_root}"
  exec {cache_lock_fd}>"${cache_root}/.${phase}.lock"
  flock "${cache_lock_fd}"
  marker="${cache_root}/${phase}/.verified"
  phase_directory="${cache_root}/${phase}"
  if [[ ! -f "${marker}" ]]; then
    rm -rf -- "${phase_directory}"
    HOMELAB_REPOSITORY_ROOT="${repository_root}" \
      HOMELAB_CACHE_ROOT="${cache_root}" \
      bash "${repository_root}/scripts/fetch-${phase}-dependencies.sh" >&2
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
    ensure_phase_dependencies phase3
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/argocd/dependencies.env"
    set +a
    argocd_chart="${ARGOCD_CHART_REF}"
    if [[ -f "${cache_root}/phase3/argo-cd/Chart.yaml" ]]; then
      argocd_chart="${cache_root}/phase3/argo-cd"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/argocd/configure-argocd.yaml" | \
      helm template argocd "${argocd_chart}" \
        --namespace argocd \
        --include-crds \
        --values -
    ;;
  platform/cilium)
    ensure_phase_dependencies phase2
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cilium/dependencies.env"
    set +a
    cilium_chart="${CILIUM_CHART_REF}"
    if [[ -f "${cache_root}/phase2/cilium/Chart.yaml" ]]; then
      cilium_chart="${cache_root}/phase2/cilium"
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
    ensure_phase_dependencies phase4
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cert-manager/dependencies.env"
    set +a
    cert_manager_chart="${CERT_MANAGER_CHART_REF}"
    if [[ -f "${cache_root}/phase4/cert-manager/Chart.yaml" ]]; then
      cert_manager_chart="${cache_root}/phase4/cert-manager"
    fi
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/cert-manager/configure-cert-manager.yaml" | \
      helm template cert-manager "${cert_manager_chart}" \
        --namespace cert-manager \
        --include-crds \
        --values - | \
      bash "${repository_root}/scripts/harden-cert-manager-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cert-manager/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/external-dns)
    ensure_phase_dependencies phase4
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/external-dns/dependencies.env"
    set +a
    external_dns_chart="${cache_root}/phase4/external-dns"
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
  platform/snapshot-controller)
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/snapshot-controller/dependencies.env"
    set +a
    kustomize build "${repository_root}/platform/snapshot-controller" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/longhorn)
    ensure_phase_dependencies phase5
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/longhorn/dependencies.env"
    set +a
    longhorn_chart="${cache_root}/phase5/longhorn"
    test -f "${longhorn_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/longhorn/configure-longhorn.yaml" | \
      helm template longhorn "${longhorn_chart}" \
        --namespace longhorn-system \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/longhorn/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/cloudnative-pg)
    ensure_phase_dependencies phase5
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/cloudnative-pg/dependencies.env"
    set +a
    export CNPG_POSTGRES_IMAGE="${POSTGRES_IMAGE}"
    cnpg_chart="${cache_root}/phase5/cloudnative-pg"
    barman_chart="${cache_root}/phase5/plugin-barman-cloud"
    test -f "${cnpg_chart}/Chart.yaml"
    test -f "${barman_chart}/Chart.yaml"
    helm template cloudnative-pg "${cnpg_chart}" \
      --namespace cnpg-system \
      --include-crds \
      --values "${repository_root}/platform/cloudnative-pg/configure-cloudnative-pg.yaml"
    printf '%s\n' '---'
    helm template barman-cloud "${barman_chart}" \
      --namespace cnpg-system \
      --include-crds \
      --values "${repository_root}/platform/cloudnative-pg/configure-barman-cloud.yaml" | \
      bash "${repository_root}/scripts/harden-barman-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/cloudnative-pg/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/velero)
    ensure_phase_dependencies phase5
    set -a
    # shellcheck disable=SC1091
    source "${repository_root}/platform/velero/dependencies.env"
    set +a
    velero_chart="${cache_root}/phase5/velero"
    test -f "${velero_chart}/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/velero/configure-velero.yaml" | \
      helm template velero "${velero_chart}" \
        --namespace velero \
        --include-crds \
        --values -
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/velero/resources" | \
      bash "${repository_root}/scripts/render-config.sh" -
    ;;
  platform/openbao)
    ensure_phase_dependencies phase6
    openbao_chart="${cache_root}/phase6/openbao"
    test -f "${openbao_chart}/Chart.yaml"
    helm template openbao "${openbao_chart}" \
      --namespace openbao \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/openbao/configure-openbao.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/openbao/resources"
    ;;
  platform/external-secrets)
    ensure_phase_dependencies phase6
    external_secrets_chart="${cache_root}/phase6/external-secrets"
    test -f "${external_secrets_chart}/Chart.yaml"
    helm template external-secrets "${external_secrets_chart}" \
      --namespace external-secrets \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/external-secrets/configure-external-secrets.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/prometheus-stack)
    ensure_phase_dependencies phase7
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/observability/prometheus-stack/configure-prometheus-stack.yaml" | \
    helm template monitoring "${cache_root}/phase7/kube-prometheus-stack" \
      --namespace monitoring \
      --include-crds \
      --skip-tests \
      --values - | \
      bash "${repository_root}/scripts/harden-observability-render.sh"
    ;;
  observability/blackbox)
    ensure_phase_dependencies phase7
    helm template blackbox "${cache_root}/phase7/blackbox-exporter" \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/blackbox/configure-blackbox-exporter.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/loki)
    ensure_phase_dependencies phase7
    helm template loki "${cache_root}/phase7/loki" \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/loki/configure-loki.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/alloy)
    ensure_phase_dependencies phase7
    helm template alloy "${cache_root}/phase7/alloy" \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/alloy/configure-alloy.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/tempo)
    ensure_phase_dependencies phase7
    helm template tempo "${cache_root}/phase7/tempo" \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/tempo/configure-tempo.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/otel-collector)
    ensure_phase_dependencies phase7
    helm template otel-collector "${cache_root}/phase7/otel-collector" \
      --namespace monitoring \
      --skip-tests \
      --values "${repository_root}/observability/otel-collector/configure-otel-collector.yaml" | \
      bash "${repository_root}/scripts/harden-runtime-secret-render.sh"
    ;;
  observability/sloth)
    ensure_phase_dependencies phase7
    helm template sloth "${cache_root}/phase7/sloth" \
      --namespace monitoring \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/observability/sloth/configure-sloth.yaml" | \
      bash "${repository_root}/scripts/harden-observability-render.sh"
    ;;
  policies/kyverno)
    ensure_phase_dependencies phase8
    helm template kyverno "${cache_root}/phase8/kyverno" \
      --namespace kyverno \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/policies/kyverno/configure-kyverno.yaml" | \
      bash "${repository_root}/scripts/harden-policy-render.sh"
    ;;
  policies/trivy)
    ensure_phase_dependencies phase8
    helm template trivy-operator "${cache_root}/phase8/trivy-operator" \
      --namespace trivy-system \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/policies/trivy/configure-trivy-operator.yaml"
    ;;
  platform/argo-rollouts)
    ensure_phase_dependencies phase9
    helm template argo-rollouts "${cache_root}/phase9/argo-rollouts" \
      --namespace argo-rollouts \
      --include-crds \
      --skip-tests \
      --values "${repository_root}/platform/argo-rollouts/configure-argo-rollouts.yaml"
    printf '%s\n' '---'
    kustomize build "${repository_root}/platform/argo-rollouts/resources"
    ;;
  platform/chaos-mesh)
    ensure_phase_dependencies phase11
    test -f "${cache_root}/phase11/chaos-mesh/Chart.yaml"
    bash "${repository_root}/scripts/render-config.sh" \
      "${repository_root}/platform/chaos-mesh/configure-chaos-mesh.yaml" | \
      helm template chaos-mesh "${cache_root}/phase11/chaos-mesh" \
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
