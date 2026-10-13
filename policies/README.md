# Policy and supply-chain controls

Kyverno starts in Audit mode and reports violations of the application workload
baseline. The separately rendered Deny overlay is promoted only after reports are clean.
Trivy Operator supplies vulnerability, SBOM, configuration, and RBAC findings without
privileged node collection.

Run `make validate-policy` for checksum verification, deterministic chart and policy
renders, strict CRD schemas, Kyverno tests, Prometheus rule checks, dashboard parsing,
workload assertions, and kube-linter. Runtime admission and scan results remain
`not run yet`.
