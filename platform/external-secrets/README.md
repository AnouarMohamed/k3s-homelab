# External Secrets Operator

External Secrets Operator exchanges short-lived, audience-bound Kubernetes service
account tokens for OpenBao tokens. Static OpenBao tokens are never stored in Git or in
bootstrap Secrets. The controller, webhook, and certificate controller each run two
digest-pinned replicas with probes, budgets, limits, topology spread, and policies.

The chart is operated through Argo CD. Namespace stores and the restricted cluster
store live under `platform/runtime-secrets`; validate everything with
`make validate-secrets`.
