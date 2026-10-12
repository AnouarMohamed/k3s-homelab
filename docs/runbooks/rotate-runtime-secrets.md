# Rotate runtime secrets

## Issue a bounded operator token

Retrieve the root token from offline custody only for this operation. The following
pipeline keeps it out of command arguments and writes the newly issued token to a
permission-restricted local file. Move that file to secure temporary custody.

```bash
install -m 0700 -d /secure/openbao
umask 077
read -rsp 'OpenBao root token: ' BAO_ROOT_TOKEN
printf '\n'
printf '%s\n' "${BAO_ROOT_TOKEN}" | kubectl exec -i -n openbao openbao-0 -- sh -c '
  IFS= read -r BAO_TOKEN
  export BAO_TOKEN BAO_ADDR=https://127.0.0.1:8200
  export BAO_CACERT=/openbao/tls/ca.crt
  bao token create -policy=runtime-secret-operator -ttl=8h \
    -renewable=false -orphan -format=json
' > /secure/openbao/operator-session.json
unset BAO_ROOT_TOKEN
```

Return the root token to offline custody. Extract the operator token without printing
it, then remove the session file from the workstation when the rotation is complete.

## Write a new version

Set only a non-secret path such as `apps-sentinel/database`. Enter both sensitive
values at hidden prompts. The runtime value travels over standard input and is not a
process argument.

```bash
read -rp 'Secret path below secret/: ' BAO_SECRET_PATH
read -rsp 'Operator token: ' BAO_OPERATOR_TOKEN
printf '\n'
read -rsp 'New secret value: ' BAO_ROTATED_VALUE
printf '\n'
printf '%s\n%s\n' "${BAO_OPERATOR_TOKEN}" "${BAO_ROTATED_VALUE}" | \
  kubectl exec -i -n openbao openbao-0 -- \
  env BAO_SECRET_PATH="${BAO_SECRET_PATH}" sh -c '
    IFS= read -r BAO_TOKEN
    IFS= read -r BAO_ROTATED_VALUE
    export BAO_TOKEN BAO_ADDR=https://127.0.0.1:8200
    export BAO_CACERT=/openbao/tls/ca.crt
    printf "%s" "${BAO_ROTATED_VALUE}" | \
      bao kv put -mount=secret "${BAO_SECRET_PATH}" value=-
  '
unset BAO_OPERATOR_TOKEN BAO_ROTATED_VALUE
```

Force only the intended `ExternalSecret` to refresh, then check its Ready condition,
the target Secret resource version, and the consuming workload. Never print the Secret.

```bash
kubectl -n <namespace> annotate externalsecret <name> \
  force-sync="$(date +%s)" --overwrite
kubectl -n <namespace> wait --for=condition=Ready externalsecret/<name> --timeout=2m
kubectl -n <namespace> get secret <name> \
  -o jsonpath='{.metadata.resourceVersion}{"\n"}'
```

If the consumer fails, write the previously retained value as another KV version and
repeat the refresh. Do not delete KV history during an incident. Revoke the operator
token early with the root token if its custody is uncertain; otherwise allow its
non-renewable eight-hour TTL to expire.
