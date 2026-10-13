# Release Homelab Sentinel

## Preconditions

- The default branch is protected and the GitLab runner supports privileged BuildKit.
- `GITLAB_PROMOTION_TOKEN`, `GHCR_USERNAME`, `GHCR_TOKEN`, and `GHCR_NAMESPACE` are
  protected and masked CI variables.
- The pipeline's test, integration, build, SBOM, Trivy, and GitLab signing jobs passed.

## Staging

The pipeline automatically runs `scripts/promote-sentinel-images.sh staging` with the
two recorded image digests and pushes the resulting lock-file commit. Confirm Argo CD
syncs `sentinel-staging`, the Rollout becomes Healthy, and its analysis succeeds.

```bash
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel-staging --watch
kubectl get analysiruns -n apps-sentinel-staging
kubectl logs -n apps-sentinel-staging deploy/sentinel-worker --since=10m
```

## Production

Review staging evidence, the SBOMs, Trivy reports, and Cosign verification output. Run
the protected manual `promote:sentinel-production` job. It updates only the production
lock file. Watch the canary and abort if the analysis fails or the status API error
rate rises.

```bash
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel --watch
kubectl get analysiruns -n apps-sentinel
kubectl get pods,pdb,hpa -n apps-sentinel
```

The GHCR mirror is publication evidence, not a production deployment source. Never
replace a digest with a tag during a release.
