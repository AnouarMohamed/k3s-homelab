# Evidence map

This index distinguishes source evidence from runtime proof. `PENDING HARDWARE` means
no physical result exists yet.

| Claim | Source evidence | Runtime proof location |
| --- | --- | --- |
| Idempotent node provisioning | [`infra/ansible`](../infra/ansible/) | Phase 1 verification ledger |
| HA networking and encryption | [`platform/cilium`](../platform/cilium/) | Cilium status/connectivity output |
| Restricted GitOps | [`clusters/homelab`](../clusters/homelab/) | Argo tree screenshot and drift exercise |
| Outbound-only access | [`infra/tofu`](../infra/tofu/) and cloudflared | Tunnel, DNS, and WARP observations |
| Recoverable data | Longhorn, CNPG, and Velero sources | Empty-until-run DR result tables |
| Runtime secret boundary | [`platform/openbao`](../platform/openbao/) | Unseal and rotation exercise |
| Metrics, logs, and traces | [`observability`](../observability/) | Redacted Grafana/Hubble screenshots |
| Admission and scanning | [`policies`](../policies/) | Reports and signature verification |
| Signed delivery | [`ci/sentinel.gitlab-ci.yml`](../ci/sentinel.gitlab-ci.yml), [GHCR application publisher](../.github/workflows/publish-ghcr-packages.yaml) | Pipeline, Rekor, GHCR, rollout evidence |
| SSO and private apps | Keycloak and [`apps`](../apps/) | Login, MFA, backup, recovery checks |
| Failure recovery | Chaos Mesh and [DR drills](dr/README.md) | Measured drill tables |
