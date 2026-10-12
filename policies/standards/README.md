# Workload admission standards

The Audit overlay reports application violations without blocking reconciliation. The
Enforce overlay changes CEL validation actions to `Deny` and the one legacy
API-context policy to `Enforce`. Only namespaces explicitly labeled
`policy.homelab.dev/profile: application` enter the workload baseline; signature and
registry checks additionally require `policy.homelab.dev/supply-chain: signed`.

The network-policy inventory check remains a legacy `ClusterPolicy` because Kyverno
1.19's CEL `ValidatingPolicy` schema has no API-call context. This compatibility debt
is tracked for the Kyverno 1.20 upgrade. Run the promotion runbook before changing the
GitOps application from `audit` to `enforce`.
