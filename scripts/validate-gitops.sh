#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/argocd"
schema_cache_dir="${repository_root}/.cache/kubeconform"

set -a
# shellcheck disable=SC1091
source "${repository_root}/platform/argocd/dependencies.env"
set +a

"${repository_root}/scripts/fetch-argocd-dependencies.sh"
mkdir -p "${schema_cache_dir}"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

render_values() {
  "${repository_root}/scripts/render-config.sh" \
    "${repository_root}/platform/argocd/configure-argocd.yaml"
}

render_values >"${validation_dir}/argocd-values-first.yaml"
render_values >"${validation_dir}/argocd-values-second.yaml"
cmp "${validation_dir}/argocd-values-first.yaml" \
  "${validation_dir}/argocd-values-second.yaml"

helm lint "${cache_dir}/argo-cd" \
  --values "${validation_dir}/argocd-values-first.yaml"
helm template argocd "${cache_dir}/argo-cd" \
  --kube-version 1.36.5 \
  --namespace argocd \
  --include-crds \
  --values "${validation_dir}/argocd-values-first.yaml" \
  >"${validation_dir}/argocd-render-first.yaml"
helm template argocd "${cache_dir}/argo-cd" \
  --kube-version 1.36.5 \
  --namespace argocd \
  --include-crds \
  --values "${validation_dir}/argocd-values-second.yaml" \
  >"${validation_dir}/argocd-render-second.yaml"
cmp "${validation_dir}/argocd-render-first.yaml" \
  "${validation_dir}/argocd-render-second.yaml"

kubeconform -strict -summary \
  -cache "${schema_cache_dir}" \
  -kubernetes-version 1.36.5 \
  -skip CustomResourceDefinition \
  "${validation_dir}/argocd-render-first.yaml"

test "$(yq eval-all \
  '[select(.kind == "CustomResourceDefinition") | select(.spec.group == "argoproj.io" and .spec.scope == "Namespaced" and (.spec.versions[] | select(.name == "v1alpha1" and .served == true and .schema.openAPIV3Schema != null)))] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 3

for crd_kind in applications applicationsets appprojects; do
  resource_kind="${crd_kind%s}"
  if [[ "${crd_kind}" == applicationsets ]]; then
    resource_kind=applicationset
  fi
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"${crd_kind}.argoproj.io\") | .spec.versions[] | select(.name == \"v1alpha1\") | .schema.openAPIV3Schema" \
    "${validation_dir}/argocd-render-first.yaml" \
    >"${schema_dir}/${resource_kind}-v1alpha1.json"
done

"${repository_root}/scripts/render-gitops.sh" \
  "${repository_root}/clusters/homelab/bootstrap" \
  >"${validation_dir}/children-first.yaml"
"${repository_root}/scripts/render-gitops.sh" \
  "${repository_root}/clusters/homelab/bootstrap" \
  >"${validation_dir}/children-second.yaml"
cmp "${validation_dir}/children-first.yaml" \
  "${validation_dir}/children-second.yaml"

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/clusters/homelab/root-app.yaml" \
  >"${validation_dir}/root-app.yaml"
{
  printf '%s\n' '---'
  cat "${validation_dir}/root-app.yaml"
  printf '%s\n' '---'
  cat "${validation_dir}/children-first.yaml"
} >"${validation_dir}/gitops-resources.yaml"

kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  "${validation_dir}/gitops-resources.yaml"

expected_repo="$(yq --unwrapScalar '.spec.gitlab.projectPath' \
  "${repository_root}/config/homelab.yaml")"
expected_repo="https://gitlab.com/${expected_repo}.git"

test "$(yq eval-all \
  '[select(.kind == "Application") | select(.spec.project == "default")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  "[select(.kind == \"Application\") | select(.spec.source.repoURL != \"${expected_repo}\")] | length" \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  '[select(.kind == "Application") | select(.spec.source.targetRevision != "main")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  '[select(.kind == "Application") | select(.spec.source.plugin.name != "homelab-renderer-v1")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  '[select(.kind == "ApplicationSet") | select(.spec.template.spec.project != "applications")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  '[select(.kind == "ApplicationSet") | select(.spec.template.spec.source.targetRevision != "main")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
project_repositories="$(
  yq --unwrapScalar \
    'select(.kind == "AppProject" and .metadata.name != "default") | .spec.sourceRepos[]' \
    "${validation_dir}/gitops-resources.yaml" | sed '/^---$/d' | sort --unique
)"
test "${project_repositories}" = "${expected_repo}"
test "$(yq eval-all \
  '[select(.kind == "AppProject") | .spec.destinations[]? | select(.server != "https://kubernetes.default.svc")] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 0
test "$(yq eval-all \
  '[select(.kind == "AppProject" and .metadata.name == "default") | select((.spec.sourceRepos | length) == 0 and (.spec.destinations | length) == 0)] | length' \
  "${validation_dir}/gitops-resources.yaml")" = 1

test "$(yq --unwrapScalar '.server.service.type' \
  "${validation_dir}/argocd-values-first.yaml")" = ClusterIP
test "$(yq --unwrapScalar '.server.ingress.enabled' \
  "${validation_dir}/argocd-values-first.yaml")" = false
test "$(yq --unwrapScalar '.server.httproute.enabled' \
  "${validation_dir}/argocd-values-first.yaml")" = false
test "$(yq \
  '.configs.cm."resource.customizations.health.argoproj.io_Application" | contains("obj.status.health")' \
  "${validation_dir}/argocd-values-first.yaml")" = true
test "$(yq eval-all --unwrapScalar \
  'select(.kind == "Deployment" and .metadata.name == "argocd-repo-server") | .spec.template.spec.automountServiceAccountToken' \
  "${validation_dir}/argocd-render-first.yaml")" = false
test "$(yq eval-all --unwrapScalar \
  'select(.kind == "Deployment" and .metadata.name == "argocd-repo-server") | .spec.template.spec.containers[] | select(.name == "homelab-renderer") | .image' \
  "${validation_dir}/argocd-render-first.yaml")" = "${ARGOCD_IMAGE}"
test "$(yq eval-all \
  '[select(.kind == "Deployment" and .metadata.name == "argocd-repo-server") | .spec.template.spec.containers[] | select(.name == "homelab-renderer") | .volumeMounts[] | select(.name == "renderer-tmp" and .mountPath == "/tmp")] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 1
test "$(yq eval-all \
  '[select(.kind == "Deployment" and .metadata.name == "argocd-repo-server") | .spec.template.spec.containers[] | select(.name != "homelab-renderer") | .volumeMounts[]? | select(.name == "renderer-tmp")] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 0
test "$(yq eval-all \
  '[.. | select(tag == "!!map" and has("containers")) | .containers[] | select(.resources.requests == null or .resources.limits == null)] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 0
test "$(yq eval-all \
  '[.. | select(tag == "!!map" and has("initContainers")) | .initContainers[] | select(.resources.requests == null or .resources.limits == null)] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 0
test "$(yq eval-all \
  '[.. | select(tag == "!!map" and has("containers")) | .containers[] | select(.image | test(":latest$"))] | length' \
  "${validation_dir}/argocd-render-first.yaml")" = 0

yq eval-all --unwrapScalar \
  'select(.kind == "ConfigMap" and .metadata.name == "argocd-cmp-cm") | .data."homelab-renderer-v1.yaml"' \
  "${validation_dir}/argocd-render-first.yaml" \
  >"${validation_dir}/plugin.yaml"
test "$(yq --unwrapScalar '.kind' "${validation_dir}/plugin.yaml")" = ConfigManagementPlugin
test "$(yq --unwrapScalar '.spec.preserveFileMode' \
  "${validation_dir}/plugin.yaml")" = false
test "$(yq --unwrapScalar '.spec.provideGitCreds' \
  "${validation_dir}/plugin.yaml")" = false
test "$(yq '.spec | length' "${validation_dir}/plugin.yaml")" = 3

credential_file="${repository_root}/clusters/homelab/bootstrap/provide-gitlab-repository-credentials.sops.yaml"
generator_file="${repository_root}/clusters/homelab/bootstrap/repository-credentials/decrypt-gitlab-repository-credentials.yaml"
test "$(sops filestatus "${credential_file}" | yq --input-format=json '.encrypted')" = true
test "$(yq --unwrapScalar '.sops.age[0].recipient' "${credential_file}")" = \
  "$(yq --unwrapScalar '.creation_rules[0].age' "${repository_root}/.sops.yaml")"
test "$(yq --unwrapScalar '.kind' "${generator_file}")" = ksops
test "$(yq --unwrapScalar '.metadata.annotations."config.kubernetes.io/function"' \
  "${generator_file}" | yq --unwrapScalar '.exec.path' -)" = ksops
test "$(yq --unwrapScalar '.files[0]' "${generator_file}")" = \
  ../provide-gitlab-repository-credentials.sops.yaml
test "$(yq '.stringData.url == null' "${credential_file}")" = true

kube-linter lint "${validation_dir}/argocd-render-first.yaml"
kube-linter lint "${validation_dir}/gitops-resources.yaml"

printf 'Argo CD and the restricted GitOps tree rendered deterministically.\n'
