# Initialize and unseal OpenBao

## Safety boundary

Run this only from a trusted administration workstation after all three OpenBao pods
exist. Initialization happens exactly once. Never paste a share or token into a shell
argument, chat, ticket, Git file, or terminal recording. Store the five shares in
separate secure locations; any three unseal the cluster. Keep the initial root token
offline after configuration.

## Initialize once

First confirm that the service is not already initialized. Exit if `Initialized` is
`true`; never initialize it again.

```bash
kubectl exec -n openbao openbao-0 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao status
install -m 0700 -d /secure/openbao
umask 077
kubectl exec -n openbao openbao-0 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao operator init -key-shares=5 -key-threshold=3 -format=json \
  > /secure/openbao/initialization.json
```

Immediately split custody of the shares, record who holds each share without recording
its value, and make an encrypted offline backup of the initialization file. Do not
leave the file on a general-purpose workstation.

## Unseal voters

For each pod, run the command three times and paste a different share at the interactive
prompt. The share is not placed in shell history.

```bash
kubectl exec -it -n openbao openbao-0 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao operator unseal
kubectl exec -it -n openbao openbao-1 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao operator unseal
kubectl exec -it -n openbao openbao-2 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao operator unseal
```

## Apply configuration

The mounted script is idempotent. It reads the root token over standard input, enables
KV v2 and Kubernetes auth when absent, and reconciles policies and roles.

```bash
read -rsp 'OpenBao root token: ' BAO_ROOT_TOKEN
printf '\n'
printf '%s\n' "${BAO_ROOT_TOKEN}" | kubectl exec -i -n openbao openbao-0 -- \
  /openbao/configuration/apply-openbao-configuration.sh
unset BAO_ROOT_TOKEN
```

Return the root token to offline custody. Follow the rotation runbook to issue an
eight-hour operator token; do not use the root token for secret writes.

## Verify

```bash
kubectl exec -n openbao openbao-0 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao status
kubectl -n openbao get pods,pvc
kubectl get clustersecretstore openbao
```

Expect one active and two standby voters, six Bound PVCs, and a Ready secret store.
Record only status and timestamps; redact cluster identifiers and never capture values.
