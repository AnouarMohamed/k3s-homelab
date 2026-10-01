# Argo CD Recovery Procedures

## Overview

This document outlines procedures for recovering Argo CD in various failure scenarios.

## Prerequisites

- Access to the Kubernetes cluster
- kubectl configured to access the cluster
- Access to the GitLab repository (for GitOps recovery)

## Recovery Scenarios

### 1. Recovering from a Failed Argo CD Deployment

If the Argo CD deployment fails or becomes unhealthy:

```bash
# Check Argo CD pod status
kubectl get pods -n argocd

# Describe problematic pods
kubectl describe pod <pod-name> -n argocd

# Check logs
kubectl logs <pod-name> -n argocd

# If needed, restart the deployment
kubectl rollout restart deployment/argocd-server -n argocd
```

### 2. Recovering GitOps State from Backup

If the GitOps state in the cluster is corrupted but GitLab repo is intact:

```bash
# Force a sync and prune to restore desired state
argocd app sync homelab-gitops --prune --force

# Or via kubectl
kubectl patch application homelab-gitops -n argocd --type merge -p '{"spec":{"syncPolicy":{"autenticated":null}}}'
```

### 3. Recovering Lost Admin Access

If admin access is lost and break-glass account is needed:

```bash
# Get break-glass credentials (if stored securely)
# Username: breakglass-admin
# Password: [retrieved from secure store]

# Login to Argo CD CLI
argocd login <argocd-server-ip>:<port>
# Username: breakglass-admin
# Password: [breakglass password]

# Alternatively, reset via Kubernetes secret (if breakglass account was created as secret)
kubectl -n argocd delete secret argocd-breakglass-admin
# Then recreate from backup
```

### 4. Recovering from GitLab Repository Loss

If the GitLab repository is lost or corrupted:

1. Restore repository from backup
2. Verify Argo CD applications can still sync
3. If applications are out of sync, force a sync:
   ```bash
   argocd app sync --all --prune
   ```

### 5. Disaster Recovery - Full Cluster Loss

In case of complete cluster loss:

1. Re-provision Kubernetes cluster (follow Phase 1 procedures)
2. Reinstall Argo CD using `make bootstrap-gitops`
3. Argo CD will automatically sync all applications from the GitLab repository
4. Verify all applications are healthy:
   ```bash
   argocd app list
   ```

## Backup Procedures

### Backing Up Argo CD Configuration

Argo CD state is stored in Kubernetes CRDs, so etcd backup includes Argo CD state.
Regular etcd backups are sufficient for Argo CD recovery.

### Backing Up GitLab Repository

Ensure GitLab repository is backed up regularly through GitLab's backup mechanisms.

## Validation After Recovery

After any recovery procedure, validate:

```bash
# Check Argo CD health
argocd cluster list
argocd app list

# Verify all applications are synced and healthy
argocd app list --sync-status Synced --health-status Healthy

# Check that critical platform components are running
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium
kubectl get pods -n cert-manager
kubectl get pods -n argocd
```

## Contact

For assistance with Argo CD recovery, refer to the runbook maintainers or consult the Argo CD documentation at https://argo-cd.readthedocs.io/