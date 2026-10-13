# Homelab Sentinel

Homelab Sentinel is the small application I use to demonstrate the complete
delivery path in this repository. A probe worker records service-state changes
in PostgreSQL. A separate, read-only API publishes only services directly
marked public and serves the status UI.

## Operate

The production and staging overlays are reconciled by Argo CD. Production uses
three CloudNativePG instances; staging uses one. Runtime credentials come from
OpenBao through External Secrets. The API provides `/healthz`, `/readyz`,
`/api/v1/status`, and `/metrics`; the worker exposes health and metrics only
inside the cluster. Probe target URLs are never returned by the public API.

GitLab CI builds multi-architecture API and worker images, creates SPDX SBOMs,
blocks high and critical vulnerabilities, signs images with GitLab OIDC, and
promotes their digests by changing the relevant `image-lock.env`. It also
mirrors three signed packages to GHCR: the API image, the worker image, and an
OCI deployment bundle containing the unrendered Kustomize sources.

## Test

Run `make -C apps/sentinel test` for race-enabled unit tests and
`scripts/test-sentinel-integration.sh` for a disposable PostgreSQL integration
test. Run `make validate-sentinel` from the repository root to build, render,
validate the complete delivery configuration and parse the k6 load scenario. Live
load execution, registry publication,
OIDC signing, Argo Rollouts analysis, and database failover remain hardware or
CI checks documented in `docs/bring-up-checklist.md`.
