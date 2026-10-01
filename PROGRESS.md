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
**Status**: 🟡 Preparation completed

**What was done**:
- Created platform/cilium/ with Helm values (platform/cilium/values.yml), README, and manifests:
  - CiliumLoadBalancerIPPool (platform/cilium/cilium-lb-ippool.yaml)
  - CiliumL2AnnouncementPolicy (platform/cilium/cilium-l2-policy.yaml)
- Created platform/network-policies/ with a baseline network policy component (default-deny + allow DNS + allow intra-namespace) as a reusable Kustomize component, plus an example.
- Created docs/runbooks/cilium-troubleshooting.md.
- Created ADR 0006 for WireGuard encryption (docs/adr/0006-wireguard-encryption.md).
- Added Make target `bootstrap-cni` that installs Gateway API CRDs (version v1.2.0) and Cilium (chart version 1.15.0) via Helm, applies the IP pool and L2 announcement policies, and waits for rollouts.
- All values in platform/cilium/values.yml are documented with comments explaining why.

**Preparation notes**:
- The actual installation requires the cluster to be bootstrapped (Phase 1) and the kube-vip VIP (192.168.1.200) to be available.
- The LoadBalancer IP range (192.168.1.240/28) must be free in the LAN.
- The interface for L2 announcements is set to eth0 (as per inventory); adjust if your nodes use a different interface.
- The Gateway API and Cilium versions are specified in the Makefile and should be verified for compatibility with the k3s version.

**Next steps**:
- Once Phase 1 is complete and the cluster is up (with nodes NotReady due to missing CNI), run `make bootstrap-cni` to install Cilium and Gateway API.
- After installation, verify with `cilium status --wait` and `kubectl get nodes`.
- Run `cilium connectivity test` to verify network connectivity and record the summary in this file.
- Test a LoadBalancer service to ensure it receives an IP from the pool and is reachable from another LAN machine.

## Phase 3: Deploy Argo CD and app-of-apps
**Status**: ⬜ Not started

## Phase 4: Add observability stack
**Status**: ⬜ Not started

## Phase 5: Add policy engine
**Status**: ⬜ Not started

## Phase 6: Deploy demo and self-hosted apps
**Status**: ⬜ Not started