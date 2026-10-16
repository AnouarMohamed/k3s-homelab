# Runtime secret stores

The cluster store authenticates with an audience-bound token minted for a dedicated
service account; it contains no static OpenBao token. Its namespace condition and
OpenBao role limit it to the `external-secrets` path and namespace.

Application phases add namespaced stores, matching `openbao-auth` service accounts,
and exact token-mint RoleBindings when they introduce a real secret consumer. The
OpenBao policy bundle already reserves isolated paths for existing bootstrap
namespaces; no `ExternalSecret` is committed until a real key is seeded and consumed.

The OpenBao server CA is public trust material, not a credential. A least-privilege
Kubernetes provider reads only `openbao/openbao-server-tls`, and a
`ClusterExternalSecret` copies only `ca.crt` into explicitly labelled consumer
namespaces. Namespaced Vault stores then reference their local `openbao-ca` Secret, as
required by External Secrets Operator v1 namespace scoping.
