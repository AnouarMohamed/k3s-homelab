# Argo CD Sync Waves and Ordering

## Overview

Argo CD sync waves allow you to control the order in which resources are synchronized during an application sync operation. Lower numbers are synced first.

## Sync Wave Ordering for Homelab Cluster

The following sync wave ordering is implemented to ensure proper dependency management:

| Sync Wave | Component | Description |
|-----------|-----------|-------------|
| 0 | CRDs & CNI | Custom Resource Definitions and Container Network Interface (Cilium) |
| 1 | Argo CD (Self-managed) | Argo CD control plane components |
| 2 | cert-manager | Certificate management for TLS |
| 3 | Storage | Longhorn distributed block storage |
| 4 | Secrets | OpenBao (Vault-compatible) secrets management |
| 5 | Observability | Prometheus, Grafana, Loki, etc. |
| 6 | Applications | User applications and demo apps |

## Implementation

Each ApplicationSet or Application uses the `argocd.argoproj.io/sync-wave` annotation to specify its wave:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "<wave-number>"
```

## Dependency Management

This ordering ensures that:
1. CRDs are available before operators that depend on them
2. CNI is installed before workloads that require networking
3. Argo CD is available before it manages other applications
4. cert-manager is available before services that need TLS certificates
5. Storage is available before stateful workloads
6. Secrets management is available before applications that need secrets
7. Observability is available before applications that emit metrics/logs
8. Applications are deployed last, after all platform services are ready

## Modifying Sync Waves

To change the sync wave of a component:
1. Locate the Application manifest in `clusters/homelab/apps/`
2. Update the `argocd.argoproj.io/sync-wave` annotation
3. Commit and push changes to trigger Argo CD sync

## Troubleshooting

If resources are not syncing in the expected order:
1. Verify the sync-wave annotations are correctly set
2. Check that dependencies are actually required (some components may not have hard dependencies)
3. Review Argo CD sync logs for ordering information