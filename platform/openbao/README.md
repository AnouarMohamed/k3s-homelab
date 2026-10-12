# OpenBao

OpenBao runs three TLS-only Raft voters on Longhorn. Each voter receives retained data
and audit PVCs; a declarative file audit device writes JSON to the audit volume. The UI
is ClusterIP-only. Shamir initialization and unseal remain deliberate human actions.

The mounted configuration script idempotently enables KV v2, configures Kubernetes
authentication, and reconciles read-only policies and short-lived roles for each
runtime namespace. A separate write-only secret-data policy can be attached to an
eight-hour token for a supervised rotation session; it grants no system, auth, or
policy administration. Operate OpenBao only through the initialization, rotation,
and break-glass runbooks. Validate the chart and configuration with
`make validate-secrets`.
