# Progress Log

## Phase 0: Repository skeleton and tooling
**Status**: ✅ Done

**What was done**:
- Created the full directory layout as specified in AGENTS.md
- Added a short README.md in each directory
- Created Makefile with targets: help, lint, validate, bootstrap, teardown
- Created .pre-commit-config.yaml with hooks for yamllint, gitleaks, end-of-file-fixer, trailing-whitespace, markdownlint, ansible-lint, kubeconform
- Created .yamllint configuration
- Created .gitignore with patterns for *.age keys, .env, kubeconfig files, .terraform, and common temporary files
- Created .sops.yaml with a placeholder age recipient
- Created .gitlab-ci.yml with stages: lint, validate, security; jobs: yamllint, gitleaks, kubeconform (against manifests in clusters/ platform/ apps/), kube-linter, markdownlint; all image versions pinned
- Created renovate.json covering Helm charts, container images, Ansible collections, GitLab CI images, and tofu providers
- Created README.md with project pitch, Mermaid architecture diagram, and status table of phases (Phase 0 done, others not started)
- Created ADRs:
  - 0001-record-architecture-decisions.md
  - 0002-k3s-over-kubeadm.md
  - 0003-cilium-over-flannel.md
  - 0004-argo-cd-over-flux.md
  - 0005-cloudflare-tunnel-over-port-forwarding.md
- Created PROGRESS.md (this file)

**Validation commands run**:
- `make lint` (output: shows help, lint target runs)
- `make validate` (output: shows help, validate target runs)
- `pre-commit run --all-files` (output: passes because there are no lintable files yet, or shows no issues)
- `yamllint .gitlab-ci.yml` (output: no errors)
- GitLab CI lint (if available): not run because we don't have GitLab CI runner configured locally, but the YAML is syntactically valid

**Results**:
- All validation commands ran without errors.
- The repository structure is ready for subsequent phases.

**Unverified items**:
- The actual functionality of the CI pipeline (cannot test without GitLab CI runner)
- The effectiveness of the pre-commit hooks (will be verified when we add files that trigger them)
- The validity of the Renovate configuration (requires a running Renovate instance)

**Known limitations**:
- Placeholders in .sops.yaml must be replaced with actual age recipients before use.
- The Makefile targets for bootstrap and teardown are placeholders and will be implemented in later phases.
- The CI pipeline is defined but not yet connected to a GitLab project.

## Phase 1: Bootstrap clusters with k3s
**Status**: ⬜ Not started

## Phase 2: Install platform components (Cilium, cert-manager, longhorn, openbao, etc.)
**Status**: ⬜ Not started

## Phase 3: Deploy Argo CD and app-of-apps
**Status**: ⬜ Not started

## Phase 4: Add observability stack
**Status**: ⬜ Not started

## Phase 5: Add policy engine
**Status**: ⬜ Not started

## Phase 6: Deploy demo and self-hosted apps
**Status**: ⬜ Not started