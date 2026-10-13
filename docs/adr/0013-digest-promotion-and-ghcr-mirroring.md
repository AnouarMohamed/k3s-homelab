# ADR 0013: Promote digests and mirror release packages to GHCR

## Context

I need staging to update automatically after a successful build while production
remains an explicit decision. GitLab is the deployment and CI source, but I also want
the public release artifacts to be easy to inspect through GHCR. Rebuilding an image
for each environment or registry would make the tested bytes differ from the deployed
bytes.

## Decision

GitLab CI builds one `linux/amd64,linux/arm64` OCI index for each Sentinel binary. It
records the registry digest, generates and attests an SPDX SBOM, applies the Trivy
gate, and signs the digest with GitLab OIDC. Staging promotion changes only the staging
`image-lock.env`; production promotion is a protected manual job that changes only the
production lock.

After those gates, the pipeline copies the same OCI indexes to
`ghcr.io/<namespace>/homelab-sentinel-api` and
`ghcr.io/<namespace>/homelab-sentinel-worker`. It also publishes the unrendered
Kustomize sources as `homelab-sentinel-deploy`. All three GHCR artifacts are signed.
Cluster deployment continues to pull the GitLab registry digests so GitLab remains the
single delivery authority.

The GitHub mirror additionally publishes one unrendered, keylessly signed deployment
source package for Homepage, Keycloak, Sentinel, Uptime Kuma, Vaultwarden, and whoami.
That workflow uses GitHub's repository-scoped token and OIDC identity. It does not
build or promote workload images, so GitLab remains the only delivery authority.

## Rejected alternatives

- I rejected tag-based deployment because a tag can resolve to different bytes later.
- I rejected independent GitHub Actions image builds because they create a second CI
  authority and cannot prove that GitLab tested the same image. Publishing unrendered
  source bundles from the mirror does not cross that boundary.
- I rejected editing a shared base image reference because it would promote staging
  and production together.

## Tradeoff

The GitLab mirror job needs protected push credentials and a narrowly scoped GitHub
package token. The GitHub source-package workflow uses its short-lived repository
token instead. Promotion creates small Git commits, and a `[skip ci]` guard is required
to prevent recursion. GHCR is a release mirror, so its availability is not required
for cluster reconciliation.
