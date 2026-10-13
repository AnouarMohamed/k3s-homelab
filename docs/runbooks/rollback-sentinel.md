# Roll back Homelab Sentinel

## Abort an active canary

```bash
kubectl argo rollouts abort sentinel-api -n apps-sentinel
kubectl argo rollouts undo sentinel-api -n apps-sentinel
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel --watch
```

These commands affect the cluster and are `PENDING HARDWARE`; do not run them from
repository automation.

## Restore the GitOps source

Find the previous known-good API and worker digests in Git history. Run the promotion
helper locally with those exact digests, review the diff, and commit the two lock-file
changes. Do not edit the base or use a mutable tag.

```bash
git log -p -- apps/sentinel/overlays/prod/image-lock.env
scripts/promote-sentinel-images.sh prod sha256:<api-digest> sha256:<worker-digest>
git diff -- apps/sentinel/overlays/prod/image-lock.env
```

If a schema migration is incompatible, stop. The migrations are forward-only; restore
the database according to the CloudNativePG recovery runbook before promoting an older
binary. Record the incident and the exact database recovery point.
