#!/bin/sh
set -eu

IFS= read -r BAO_TOKEN
export BAO_TOKEN
export BAO_ADDR=https://127.0.0.1:8200
export BAO_CACERT=/openbao/tls/ca.crt

if ! bao secrets list -format=json | grep -q '"secret/"'; then
  bao secrets enable -path=secret -version=2 kv
fi

if ! bao auth list -format=json | grep -q '"kubernetes/"'; then
  bao auth enable kubernetes
fi

bao write auth/kubernetes/config \
  kubernetes_host="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}"

bao policy write runtime-secret-operator \
  /openbao/configuration/operator-write.hcl

for policy_file in /openbao/configuration/policy-*.hcl; do
  namespace="${policy_file##*/policy-}"
  namespace="${namespace%.hcl}"
  bao policy write "runtime-${namespace}" "${policy_file}"
  bao write "auth/kubernetes/role/runtime-${namespace}" \
    bound_service_account_names=openbao-auth \
    bound_service_account_namespaces="${namespace}" \
    audience=openbao \
    policies="runtime-${namespace}" \
    token_ttl=15m \
    token_max_ttl=30m
done

unset BAO_TOKEN
printf 'Applied KV v2, Kubernetes auth, namespace policies, roles, and operator policy.\n'
