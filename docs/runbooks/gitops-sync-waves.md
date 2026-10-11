# GitOps sync waves

Argo CD orders child Applications before workloads. A lower number runs first; health
must settle before the next wave proceeds.

| Wave | Responsibility | Current object |
| --- | --- | --- |
| `-50` | GitOps CRDs and controllers | `argocd` Application |
| `-49` | Adopt bootstrap SOPS credentials through KSOPS | `bootstrap-secrets` Application |
| `-40` | CNI and Gateway controller | `cilium` Application |
| `-30` | Certificate and DNS controllers | Added in Phase 4 |
| `-20` | Storage and database operators | Added in Phase 5 |
| `-10` | Runtime secret controllers | Added in Phase 6 |
| `0` | Observability and policy controllers | Added in Phases 7–8 |
| `10` | Application discovery | `production-applications` ApplicationSet |
| `20` | Namespaced applications | Generated production Applications |

Gateway API CRDs are checksum-verified and installed before the Cilium bootstrap. Each
later phase must choose the listed wave, wait for its CRDs/controllers, and add a real
Application only when that component exists; placeholder Applications are prohibited.

If a wave stalls, inspect the unhealthy Application and its controller logs. Do not
skip ahead or force synchronization merely to clear an out-of-sync indicator.
