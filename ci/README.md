# CI Templates and Pipelines

Reusable GitLab CI templates, pipeline definitions, and dependencies for the homelab project.

## Directory Structure

- `.gitlab-ci.yml`: The root GitLab CI pipeline definition.
- `ci/dependencies.env`: Pinned container image digests and versions for CI runner tooling (Kaniko, Trivy, Syft, Cosign).
- `ci/sentinel.gitlab-ci.yml`: Modular CI pipeline for the Sentinel Go service covering:
  - **Lint & Test**: `go vet`, unit tests with race detection (`go test -race`), and coverage profiling.
  - **Build**: Rootless container build using Kaniko (`gcr.io/kaniko-project/executor`) pushing immutable commit-tagged images to the GitLab Container Registry.
  - **SBOM & Attestation**: Software Bill of Materials generation in SPDX JSON format via Syft (`anchore/syft`).
  - **Vulnerability Scanning**: Trivy container vulnerability scanner (`aquasec/trivy`) gating releases against critical/high CVEs.
  - **Supply Chain Signing**: Keyless cryptographic container signing and SBOM attestation via Sigstore Cosign using GitLab CI OIDC identity tokens.
  - **Promotion**: Staging promotion and gated manual promotion to production.

## Operational Verification

Local test execution is wired into the root `Makefile`:

```bash
make test
```
