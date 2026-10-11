# Progress Log

This file records only commands actually run and results actually observed. Runtime
checks against the three physical nodes are tracked separately as `PENDING HARDWARE`.

## Phase checklist

- [x] Phase 0 — Skeleton and CI (offline validation complete)
- [x] Phase 1 — Nodes and k3s (offline validation complete; pending hardware)
- [x] Phase 2 — Cilium (offline validation complete; pending hardware)
- [x] Phase 3 — Argo CD (offline validation complete; pending hardware)
- [ ] Phase 4 — Certificates, DNS, and public access
- [ ] Phase 5 — Storage and backups
- [ ] Phase 6 — Runtime secrets
- [ ] Phase 7 — Observability
- [ ] Phase 8 — Policy and supply chain
- [ ] Phase 9 — Homelab Sentinel and delivery
- [ ] Phase 10 — Identity and self-hosted applications
- [ ] Phase 11 — Chaos and disaster recovery
- [ ] Phase 12 — Portfolio polish

## Recovery audit — 2026-10-11

- Preserved the four existing commits; the repository will be repaired forward.
- The previous Phase 0–3 claims were removed because their validation evidence was
  absent or contradicted by local checks.
- `yamllint .` returned exit 1 with 40 errors and 1,390 warnings.
- `ansible-lint infra/ansible` returned exit 2 with 43 fatal violations.
- `ansible-playbook --syntax-check` passed for `site.yml`, `upgrade.yml`, and
  `reset.yml` using the example inventory.
- `kubectl kustomize clusters/homelab` returned exit 1 because the root lacked a
  kustomization file.
- The review found hard-coded private addresses outside the central config, invalid
  Cilium fields, invalid Argo CD resources, plaintext fake secret files, an ignored
  `.sops.yaml`, unpinned `alpine:latest`, and expected output presented as observed.

## Tool inventory — 2026-10-11

Present: git, helm, kubectl, yamllint, ansible, ansible-lint, cosign, k6.

Missing at audit time: kubeconform, kube-linter, markdownlint, shellcheck, tofu, sops,
age, gitleaks, kyverno, promtool, kustomize.

`make tools` subsequently installed the missing tools into ignored `.tools/bin`. The
installer pins kubeconform `v0.8.0`, kube-linter `v0.8.3`, gitleaks `v8.30.1`, Kyverno
CLI `v1.19.1`, Kustomize `v5.7.1`, age `v1.3.2`, yq `v4.54.1`, SOPS `v3.13.3`,
OpenTofu `v1.13.1`, promtool `3.15.0`, markdownlint-cli2 `0.23.3`, and ShellCheck
`0.11.0`. Go module sums, npm integrity metadata, or upstream release checksums are
verified according to the distribution method. ShellCheck's release digest is pinned
explicitly because that release has no checksum-list asset.

## Phase 0 validation — 2026-10-11

- `make tools` returned exit 0. Release checksum output reported `OK` for Kyverno,
  OpenTofu, Prometheus, and ShellCheck.
- `make lint` returned exit 0. Markdownlint reported 36 files and zero issues;
  ansible-lint reported zero failures and zero warnings. No Ansible implementation
  files exist yet, so the latter is a configuration check rather than a Phase 1 gate.
- `make validate` returned exit 0. Forbidden-file, private-value/domain, and dependency
  pin checks passed. It correctly reported that no built-in Kubernetes manifests exist
  yet.
- `sops filestatus` reported `{"encrypted":true}` for the placeholder GitLab
  credential document. Encrypted source files are excluded from direct kubeconform;
  their decrypted in-memory render becomes a Phase 3 validation input.
- `jq empty renovate.json` returned exit 0.
- `make security` returned exit 0. Gitleaks scanned all six commits, approximately
  2.03 MB, and reported no leaks.
- `git diff --check` returned exit 0.
- The generated GitLab pipeline has not run; CI execution remains unverified.

## Phase 1 validation — 2026-10-11

- The official k3s `v1.36.5+k3s1` amd64 checksum list reported
  `d73847bcd3c5fccef0115b372e2f9a91f3032dc84bbf71518a4617565294d313`
  for `k3s`; that checksum is enforced by `get_url`.
- OCI inspection of kube-vip `v1.2.4` reported index digest
  `sha256:dde4c0669d9058c74c69c0bc2f0122e26900e1e4b913c03577cb6e4e28083079`;
  the static-pod image uses that digest.
- Ansible Galaxy returned community.general `13.4.0` with artifact SHA-256
  `efd1c0b5dc6f89b9667e4bd77f2426c30545861910dba188593871095ede1804`.
- `ansible-inventory --graph` returned `pc-1` in `initial_server` and `pc-2`/`pc-3`
  in `joining_servers`, derived from `config/homelab.yaml`.
- Syntax checks returned exit 0 for `site.yaml`, `upgrade.yaml`, and `reset.yaml`.
- Production-profile `ansible-lint infra/ansible` processed 28 files with zero
  failures and zero warnings.
- `make ansible-templates` rendered and parsed k3s, audit-policy, and kube-vip
  templates: five tasks passed, with `changed=0`.
- `make validate` returned exit 0 with the Phase 1 syntax/template gates included.
- `make security` scanned the staged working tree (approximately 106.55 KB) and all
  seven existing commits (approximately 2.08 MB); both scans reported no leaks. Local
  ignored tool/cache directories are explicitly excluded from the directory scan.
- `make reset` without confirmation returned exit 2 and printed the expected refusal;
  the destructive playbook was not started.
- No playbook was run against a node. Convergence, second-run idempotence, hardening,
  VIP movement, etcd quorum, S3 snapshots, upgrade, and reset remain
  `PENDING HARDWARE`.

## Phase 2 validation — 2026-10-11

- The pinned Cilium `1.20.2` chart resolved to OCI digest
  `sha256:a7c12d330dd96bfcda3bf057b24be8f36566c34868265f930f776dff6f42d838`.
- SHA-256 verification returned `OK` for the Gateway API `v1.6.1` standard manifest
  and the two Cilium CRDs used to validate LB IPAM and L2 announcement resources.
- `helm lint` reported one chart linted and zero failures.
- Two independently rendered Cilium value files, Helm outputs, and Cilium resource
  outputs compared byte-for-byte equal.
- Strict kubeconform validation reported 56 valid chart resources, zero invalid,
  zero errors, and zero skipped. Validation against schemas extracted from the pinned
  Cilium CRDs reported two valid custom resources with no invalid or skipped objects.
- Kube-linter reported no lint errors for the reusable default-deny component.
- `make lint` returned exit 0. Ansible-lint reported zero failures and warnings, and
  markdownlint reported 45 files with zero issues.
- `make validate` returned exit 0 with the Phase 1 and Phase 2 gates composed. The
  generic manifest pass reported four valid built-in resources with no errors or
  skipped objects.
- A second `make validate-cni` run using the ignored kubeconform schema cache returned
  exit 0 in approximately seven seconds with the same 56/56 and 2/2 results.
- `make security` scanned the staged working tree and all nine commits, approximately
  2.13 MB of history, and reported no leaks. The allowlist recognizes only explicit
  uppercase `*_SHA256` assignments as public checksum material.
- No manifest was applied to a cluster. Node readiness, Cilium health, GatewayClass
  availability, connectivity, L2 address advertisement, and WireGuard encryption
  remain `PENDING HARDWARE`.

## Phase 3 validation — 2026-10-11

- `helm show chart` and `helm pull` resolved Argo CD chart `10.10.2`, application
  `v3.5.4`, to OCI digest
  `sha256:96ff0d2150557ceb51c309c3adedb63455226c2dd2c5323f5b1e894536e2901d`.
- Registry inspection resolved the Argo CD `v3.5.4`, KSOPS `v4.5.1`, and yq `4.54.1`
  sidecar artifacts to the immutable digests recorded in
  `platform/argocd/dependencies.env`.
- `helm lint` reported one chart linted and zero failures. Two independent value and
  chart renders compared byte-for-byte equal.
- Strict kubeconform reported 52 valid chart resources and no errors. It skipped the
  three CRD objects because the Kubernetes schema set does not publish a CRD schema;
  the validator separately confirmed their group, scope, served version, and embedded
  OpenAPI schema.
- The root Application, four child Applications/ApplicationSets, and four restricted
  AppProjects rendered twice identically. Validation against schemas extracted from
  the pinned Argo CD CRDs reported nine valid resources with zero errors or skips.
- Boundary assertions confirmed GitLab-only sources, revision `main`, no Application
  in the default project, a hard-coded ApplicationSet project, a deny-all default
  project, an internal-only server, an isolated CMP temporary volume, disabled CMP Git
  credential sharing, and no repo-server service-account token mount.
- Kube-linter reported no findings for either the 55-object chart output or the GitOps
  resource tree. The workload render also contained requests and limits for every
  container and no `latest` image.
- `make lint` returned exit 0. Markdownlint checked 49 files with no issues, and the
  production Ansible profile again reported zero failures and warnings.
- `make validate` returned exit 0 with the Phase 1, Cilium, GitOps, repository-policy,
  and generic four-resource manifest gates composed.
- A CMP-like render with `GIT_DIR` deliberately invalid succeeded by using the injected
  repository root, proving the renderer does not require `.git` metadata in the sidecar
  tar stream.
- `sops filestatus` reported the repository credential document encrypted. The KSOPS
  generator and recipient linkage passed structural checks; decryption was not attempted
  because the disposable recipient's private identity is intentionally unavailable.
- `make bootstrap-gitops` stopped before any Kubernetes command because the central
  config still contains `CHANGE_ME_*` values. No cluster or remote repository was
  modified.
- `make security` scanned the staged working tree and all ten existing commits,
  approximately 2.13 MB of history, and reported no leaks.
- Argo controller health, repository authentication, root synchronization, RBAC login,
  self-healing, and Cilium adoption remain `PENDING HARDWARE`.

## Unverified

- All real-hardware behavior.
- Every dependency not yet listed with upstream evidence in `PLAN.md`.
- The GitLab pipeline, until run by GitLab.

## Not done

- No real node, cluster, Cloudflare account, S3 service, or Git remote was modified.
