# Compatibility and upgrade order

The dependency files record every exact version and digest. This table captures the compatibility
boundaries that matter during an upgrade.

| Layer | Current baseline | Compatibility boundary |
| --- | --- | --- |
| Kubernetes | k3s `v1.36.5+k3s1` | Cilium 1.20 guaranteed matrix ends at Kubernetes 1.36 |
| Network | Cilium `1.20.2`, Gateway API `v1.6.1` | Install Gateway CRDs before Cilium; retain kube-proxy replacement flags |
| GitOps | Argo CD chart `10.10.2`, app `v3.5.4` | Test CMP rendering and ApplicationSet project pinning |
| Storage | Longhorn `1.12.1`, CNPG `1.30.1`, Velero `1.18.2` | Verify CSI, plugins, and restores first |
| Secrets | OpenBao `2.7.1`, ESO `v2.12.0` | Preserve manual unseal and Kubernetes auth recovery |
| Policy | Kyverno `v1.19.1`, Trivy Operator `0.35.0` | Keep Audit until post-upgrade reports are reviewed |
| Delivery | Argo Rollouts `v1.9.1` | Validate CRDs before controller and application changes |
| Identity | Keycloak `26.8.0` | Export realm and test local break glass first |
| Resilience | Chaos Mesh `2.8.4` | Confirm k3s socket and cert-manager `v1` rendering |

Upgrade one layer at a time with the
[platform upgrade runbook](runbooks/upgrade-platform.md). Every change requires two
identical renders, schema validation, a secret scan, and matching hardware checks.
