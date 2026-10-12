#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
cache_dir="${repository_root}/.cache/phase4"
schema_cache_dir="${repository_root}/.cache/kubeconform"

# shellcheck disable=SC1091
source "${repository_root}/platform/cilium/dependencies.env"

"${repository_root}/scripts/fetch-phase2-dependencies.sh"
"${repository_root}/scripts/fetch-phase4-dependencies.sh"
mkdir -p "${schema_cache_dir}"

validation_dir="$(mktemp -d)"
trap 'rm -rf "${validation_dir}"' EXIT
schema_dir="${validation_dir}/schemas"
mkdir -p "${schema_dir}"

render_twice() {
  local source_path="$1"
  local output_name="$2"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" \
    >"${validation_dir}/${output_name}-first.yaml"
  "${repository_root}/scripts/render-gitops.sh" "${source_path}" \
    >"${validation_dir}/${output_name}-second.yaml"
  cmp "${validation_dir}/${output_name}-first.yaml" \
    "${validation_dir}/${output_name}-second.yaml"
}

render_twice "${repository_root}/platform/cert-manager" cert-manager
render_twice "${repository_root}/platform/external-dns" external-dns
render_twice "${repository_root}/platform/gateways" gateways
render_twice "${repository_root}/platform/cloudflared" cloudflared
render_twice "${repository_root}/apps/whoami/overlays/prod" whoami

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/cert-manager/configure-cert-manager.yaml" \
  >"${validation_dir}/cert-manager-values.yaml"
helm lint "${cache_dir}/cert-manager" \
  --values "${validation_dir}/cert-manager-values.yaml"

"${repository_root}/scripts/render-config.sh" \
  "${repository_root}/platform/external-dns/configure-external-dns.yaml" \
  >"${validation_dir}/external-dns-values.yaml"
helm lint "${cache_dir}/external-dns" \
  --values "${validation_dir}/external-dns-values.yaml"

for manifest in external-dns cloudflared; do
  kubeconform -strict -summary \
    -cache "${schema_cache_dir}" \
    -kubernetes-version 1.36.5 \
    "${validation_dir}/${manifest}-first.yaml"
done

kubeconform -strict -summary \
  -cache "${schema_cache_dir}" \
  -kubernetes-version 1.36.5 \
  -skip CustomResourceDefinition,ClusterIssuer,Certificate \
  "${validation_dir}/cert-manager-first.yaml"

for resource_kind in clusterissuer certificate; do
  plural="${resource_kind}s"
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"${plural}.cert-manager.io\") | .spec.versions[] | select(.name == \"v1\") | .schema.openAPIV3Schema" \
    "${validation_dir}/cert-manager-first.yaml" \
    >"${schema_dir}/${resource_kind}-v1.json"
done
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' \
  -skip CustomResourceDefinition,Namespace,ServiceAccount,Service,Deployment,PodDisruptionBudget,NetworkPolicy,Role,RoleBinding,ClusterRole,ClusterRoleBinding,MutatingWebhookConfiguration,ValidatingWebhookConfiguration,APIService,ConfigMap,Job \
  "${validation_dir}/cert-manager-first.yaml"

for resource_kind in gateway httproute; do
  plural="${resource_kind}s"
  yq eval-all --output-format=json \
    "select(.kind == \"CustomResourceDefinition\" and .metadata.name == \"${plural}.gateway.networking.k8s.io\") | .spec.versions[] | select(.name == \"v1\") | .schema.openAPIV3Schema" \
    "${repository_root}/.cache/phase2/gateway-api-standard-${GATEWAY_API_VERSION}.yaml" \
    >"${schema_dir}/${resource_kind}-v1.json"
done
yq --output-format=json \
  '.spec.versions[] | select(.name == "v2") | .schema.openAPIV3Schema' \
  "${repository_root}/.cache/phase2/cilium-network-policy-crd.yaml" \
  >"${schema_dir}/ciliumnetworkpolicy-v2.json"
sed \
  -e 's/CHANGE_ME_DOMAIN/example.invalid/g' \
  -e 's/CHANGE_ME_LOAD_BALANCER_START_IP/192.0.2.10/g' \
  "${validation_dir}/gateways-first.yaml" \
  >"${validation_dir}/gateways-schema-input.yaml"
sed \
  -e 's/CHANGE_ME_DOMAIN/example.invalid/g' \
  "${validation_dir}/whoami-first.yaml" \
  >"${validation_dir}/whoami-schema-input.yaml"
kubeconform -strict -summary \
  -schema-location "${schema_dir}/{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -reject '*' \
  -skip Namespace,Deployment,Service,PodDisruptionBudget,NetworkPolicy \
  "${validation_dir}/gateways-schema-input.yaml" \
  "${validation_dir}/whoami-schema-input.yaml"

for secret_file in "${repository_root}"/clusters/homelab/bootstrap/edge-secrets/*.sops.yaml; do
  test "$(sops filestatus "${secret_file}" | yq --input-format=json '.encrypted')" = true
  test "$(yq --unwrapScalar '.sops.age[0].recipient' "${secret_file}")" = \
    "$(yq --unwrapScalar '.creation_rules[0].age' "${repository_root}/.sops.yaml")"
done

test "$(yq eval-all '[select(.kind == "Gateway")] | length' \
  "${validation_dir}/gateways-first.yaml")" = 2
test "$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "cloudflared") | select(.spec.replicas >= 2)] | length' \
  "${validation_dir}/cloudflared-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "HTTPRoute" and .metadata.name == "whoami") | .spec.hostnames[] | select(. == "whoami.CHANGE_ME_DOMAIN")] | length' \
  "${validation_dir}/whoami-first.yaml")" = 1
test "$(yq eval-all '[.. | select(tag == "!!map" and has("containers")) | .containers[] | select(.image | test(":latest($|@)"))] | length' \
  "${validation_dir}"/*-first.yaml)" = 0
test "$(yq eval-all '[select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.resources.requests == null or .resources.limits == null or .livenessProbe == null or .readinessProbe == null)] | length' \
  "${validation_dir}"/*-first.yaml)" = 0
test "$(yq eval-all '[select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.securityContext.allowPrivilegeEscalation != false or .securityContext.readOnlyRootFilesystem != true or (.securityContext.capabilities.drop | contains(["ALL"]) | not))] | length' \
  "${validation_dir}"/*-first.yaml)" = 0
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "cert-manager")] | length' \
  "${validation_dir}/cert-manager-first.yaml")" -ge 3
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "external-dns")] | length' \
  "${validation_dir}/external-dns-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "cloudflare")] | length' \
  "${validation_dir}/cloudflared-first.yaml")" = 1
test "$(yq eval-all '[select(.kind == "NetworkPolicy" and .metadata.namespace == "apps-whoami")] | length' \
  "${validation_dir}/whoami-first.yaml")" = 1

kube-linter lint \
  "${validation_dir}/cloudflared-first.yaml" \
  "${validation_dir}/whoami-first.yaml"

tofu -chdir="${repository_root}/infra/tofu" fmt -check -recursive
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${repository_root}/.cache/tofu-plugins}"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
tofu -chdir="${repository_root}/infra/tofu" init -backend=false -input=false
tofu -chdir="${repository_root}/infra/tofu" validate

plan_root="${validation_dir}/repository"
mkdir -p "${plan_root}/infra/tofu" "${plan_root}/config"
cp \
  "${repository_root}/infra/tofu/main.tf" \
  "${repository_root}/infra/tofu/outputs.tf" \
  "${repository_root}/infra/tofu/providers.tf" \
  "${repository_root}/infra/tofu/variables.tf" \
  "${repository_root}/infra/tofu/versions.tf" \
  "${repository_root}/infra/tofu/.terraform.lock.hcl" \
  "${plan_root}/infra/tofu/"
yq \
  '.spec.domain = "example.invalid" | .spec.network.privateRouteCidr = "192.0.2.0/24"' \
  "${repository_root}/config/homelab.yaml" \
  >"${plan_root}/config/homelab.yaml"
tofu -chdir="${plan_root}/infra/tofu" init -backend=false -input=false >/dev/null
tofu -chdir="${plan_root}/infra/tofu" validate >/dev/null
export CLOUDFLARE_API_TOKEN=validation-placeholder-token
export TF_VAR_cloudflare_account_id=00000000000000000000000000000000
export TF_VAR_cloudflare_zone_id=11111111111111111111111111111111

grep -q "\.spec\.storage\.s3\.endpoint" \
  "${repository_root}/scripts/initialize-tofu-backend.sh"
grep -q "\.spec\.storage\.s3\.bucket" \
  "${repository_root}/scripts/initialize-tofu-backend.sh"
tofu -chdir="${plan_root}/infra/tofu" plan \
  -no-color \
  -refresh=false \
  -lock=false \
  -input=false \
  -out="${validation_dir}/edge.tfplan" \
  >"${validation_dir}/tofu-plan.log"
grep -q 'Plan: 4 to add, 0 to change, 0 to destroy.' \
  "${validation_dir}/tofu-plan.log"

printf 'Phase 4 edge resources rendered deterministically and validated.\n'
