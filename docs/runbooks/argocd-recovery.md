# Recover Argo CD

Use this runbook from the trusted administration host. It does not authorize deleting
Applications, pruning cluster resources, or resetting nodes.

## Inspect

```bash
kubectl -n argocd get pods,applications,applicationsets,appprojects
kubectl -n argocd logs deployment/argocd-repo-server --all-containers --tail=200
kubectl -n argocd get application homelab-root -o yaml
```

Confirm that repository authentication, the `homelab-renderer-v1` sidecar, and the root
Application are healthy before changing state.

## Local break-glass access

Argo CD has no Ingress, HTTPRoute, or Cloudflare public route. Retrieve the initial
password without printing it into a shared terminal log, then connect locally:

```bash
kubectl -n argocd port-forward service/argocd-server 8443:443
argocd login localhost:8443 --username admin
```

The built-in `admin` account is the preserved local break-glass administrator.
`platform-reader` maps to the built-in read-only role. Rotate both passwords after first
login and keep recovery material outside the repository. Phase 10 adds Keycloak while
retaining this local path.

## Reconcile from Git

If controllers are healthy but declarative state is missing, validate the exact commit
locally, then reapply only the restricted projects and root Application:

```bash
make validate-gitops
kustomize build clusters/homelab/projects | scripts/render-config.sh - | kubectl apply -f -
scripts/render-config.sh clusters/homelab/root-app.yaml | kubectl apply -f -
argocd app get homelab-root --refresh
argocd app sync homelab-root
```

If Argo CD itself is unavailable, rerun `make bootstrap-gitops` with the matching age
identity. Helm upgrade and server-side apply are idempotent. Do not use `--force`, delete
the `argocd` namespace, or cascade-delete the Cilium Application during recovery.
