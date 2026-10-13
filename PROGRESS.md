# Progress Log

This file records only commands actually run and results actually observed. Runtime
checks against the three physical nodes are tracked separately as `PENDING HARDWARE`.

## Phase checklist

- [x] Phase 0 — Skeleton and CI (offline validation complete)
- [x] Phase 1 — Nodes and k3s (offline validation complete; pending hardware)
- [x] Phase 2 — Cilium (offline validation complete; pending hardware)
- [x] Phase 3 — Argo CD (offline validation complete; pending hardware)
- [x] Phase 4 — Certificates, DNS, and public access (offline validation complete; pending hardware)
- [x] Phase 5 — Storage and backups (offline validation complete; pending hardware)
- [x] Phase 6 — Runtime secrets (offline validation complete; pending hardware)
- [x] Phase 7 — Observability (offline validation complete; pending hardware)
- [x] Phase 8 — Policy and supply chain (offline validation complete; pending hardware)
- [x] Phase 9 — Homelab Sentinel and delivery (offline validation complete; pending CI and hardware)
- [x] Phase 10 — Identity and self-hosted applications (offline validation complete; pending hardware)
- [x] Phase 11 — Chaos and disaster recovery (offline validation complete; pending hardware)
- [x] Phase 12 — Portfolio polish (offline validation complete; pending hardware evidence)

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

## Phase 4 validation — 2026-10-12

- Phase 4 was committed as `884e5ef` before its full repository gate and skeptical
  review had finished. The follow-up repair preserves that history and adds the missing
  workload probes, NetworkPolicies, provider hash, split-DNS documentation, and
  evidence. The Phase 2 fetcher changed only to checksum the pinned Cilium network
  policy CRD required to validate the Phase 4 whoami policy. Renovate coverage for
  the previously omitted Cilium, Gateway API, cert-manager, and cloudflared pins was
  repaired without enabling automerge.
- The official cert-manager chart `v1.21.1` was pulled by OCI digest
  `sha256:15c0b46d9006ce8eb9ff14d1bf54d1bbfcc587bb9e24cd9fe186fb8fec56af1f`.
  The official external-dns chart `1.22.0` archive matched SHA-256
  `ec26bba67e02f46a55ac33790ad9d9ded724a163af6f6b4a63ce68f883201f4f`.
- The Cloudflare provider `5.27.0` Linux package matched upstream SHA-256
  `ae47a9f29594d57e634cc0b5b96a18da5a364f43cbd735622ce5fe808728065f`.
  `tofu init -backend=false` selected that locked provider and `tofu validate` reported
  the configuration valid.
- `make validate-edge` returned exit 0. Two independent renders compared byte-for-byte
  equal. Helm lint reported one chart and zero failures for both charts. Strict
  kubeconform reported six valid external-dns resources, four valid cloudflared
  resources, and 53 valid cert-manager built-ins with no invalid objects or errors.
- Schemas extracted from the pinned cert-manager, Gateway API, and Cilium CRDs validated
  three cert-manager resources and four Gateway/HTTPRoute/Cilium policy resources.
  The remaining objects in those schema-only passes were deliberately skipped because
  the built-in pass had already validated them.
- Workload assertions found no Deployment container missing requests, limits,
  liveness, readiness, dropped capabilities, read-only root filesystem, or privilege
  escalation denial. Each Phase 4 workload namespace rendered a NetworkPolicy;
  kube-linter reported no findings for cloudflared or whoami.
- An offline OpenTofu plan used documentation-only values in an isolated temporary
  copy and reported `Plan: 4 to add, 0 to change, 0 to destroy.` It planned one Tunnel,
  its remote configuration, the private WARP route, and the temporary whoami CNAME.
  No Cloudflare credential or API request was used.
- `make validate` returned exit 0 across Ansible, Cilium, Argo CD, Phase 4, repository
  policy, generic kubeconform, and kube-linter gates. The generic pass validated 18
  resources from 15 files with no invalid objects, errors, or skips.
- `make lint` returned exit 0. Markdownlint checked 58 files with no issues, ShellCheck
  accepted every repository script, and the Ansible production profile again reported
  zero failures and warnings.
- `make security` returned exit 0. Gitleaks scanned approximately 244.62 KB of the
  working tree and 2.24 MB across 12 commits, reporting no leaks in either scan.
- `make tofu-init` now reads the backend endpoint and bucket directly from the central
  config and requires credentials in the environment. It enables encrypted state,
  versioned-bucket recovery, path-style S3 access, and native lockfiles; it was not run
  because doing so would contact the configured S3 service. `make tofu-plan` requires
  that explicit initialization and performs no apply.
- The skeptical review found and removed an ignored legacy static inventory containing
  private addresses. The supported inventory is the tracked dynamic inventory that
  reads `config/homelab.yaml`; no private address remained in tracked or untracked
  repository files after the cleanup.
- No manifest was applied and no OpenTofu apply was run. DNS, ACME issuance, Gateway
  acceptance, tunnel redundancy, public routing, split DNS, and WARP administration
  remain `PENDING HARDWARE` or `PENDING ACCOUNT`.

## Phase 5 validation — 2026-10-12

- Official release archives matched the pinned SHA-256 values for Longhorn `1.12.1`,
  CloudNativePG `0.29.1`, Barman Cloud `0.8.1`, and Velero `12.2.1`. The five vendored
  external-snapshotter `v8.6.0` manifests also matched their individually pinned
  upstream checksums.
- `make validate-storage` returned exit 0. Helm lint reported one chart and zero
  failures for each of Longhorn, CloudNativePG, Barman Cloud, and Velero. Two renders
  of every Phase 5 component compared byte-for-byte equal.
- Strict built-in validation reported 7 valid snapshot-controller resources with 3
  CRDs skipped, 28 valid Longhorn resources with 28 custom resources skipped, 23 valid
  CNPG/Barman resources with 18 custom resources skipped, 9 valid Velero resources
  with 16 custom resources skipped, and 3 valid storage-test resources. A separate
  pass validated all 9 selected custom resources against schemas extracted from the
  pinned CRDs with no invalid, errored, or skipped objects.
- Phase-specific assertions confirmed the three-replica default Longhorn class,
  non-default local-path class, two recurring Longhorn jobs, three CNPG instances, two
  Velero schedules, encrypted SOPS placeholders, and a NetworkPolicy for every
  rendered Phase 5 controller namespace. Strict controller hardening assertions and
  kube-linter both passed.
- `make lint` returned exit 0. Markdownlint checked 70 files with no issues;
  ShellCheck and yamllint returned no findings; ansible-lint again reported zero
  failures and zero warnings across 28 processed files.
- `make validate` returned exit 0 from the staged tree across the Ansible, Cilium,
  GitOps, edge, storage, repository-policy, OpenTofu, generic kubeconform, and
  kube-linter gates. The generic pass validated 25 resources from 17 files with no
  invalid, errored, or skipped objects. The pin gate also resolved every rendered
  image variable to a digest-pinned dependency declaration.
- `make test-storage-reschedule` without `CONFIRM_STORAGE_TEST=homelab` returned exit 2
  after printing its refusal. It stopped before invoking `kubectl`.
- `make security` returned exit 0. Gitleaks scanned approximately 381 KB of the
  working tree and 2.26 MB across 13 existing commits, finding no leaks.
- The skeptical review added the two missing CNPG-system controller policies and both
  service and k3s API ports to snapshot-controller egress. It records Longhorn's
  required privileged host access in the infrastructure exception ledger instead of
  claiming the upstream storage workloads meet application restrictions. CNPG-created
  PostgreSQL pods remain runtime-generated and require hardware verification.
- The exact upstream snapshot-controller manifests are excluded from source-format
  linting and direct source image checks: all five files are checksum-verified, and the
  Kustomize overlay replaces the upstream tag with the recorded controller digest
  before the rendered workload is validated.
- S3 bucket creation is not modeled because the central configuration intentionally
  names only a vendor-neutral endpoint and bucket; no correct provider can be selected
  without inventing the service. Anouar creates and versions the bucket as a human-only
  account task. OpenTofu continues to consume it as the encrypted remote-state backend.
- No cluster, S3 endpoint, disk, Cloudflare account, or Git remote was modified.
  Volume scheduling, replica recovery, WAL archival, backup completion, and every
  restore remain `PENDING HARDWARE` or `PENDING ACCOUNT`.

## Phase 6 validation — 2026-10-12

- Official release archives matched the pinned SHA-256 values for OpenBao chart
  `0.30.3` and External Secrets chart `2.12.0`. Their application images use the
  recorded immutable OCI index digests for OpenBao `2.7.1` and External Secrets
  `v2.12.0`.
- `make validate-secrets` returned exit 0. Helm lint reported one chart and zero
  failures for each component, and two independent renders of the prerequisites,
  OpenBao, External Secrets, and runtime store compared byte-for-byte equal.
- Strict built-in validation reported 2 valid prerequisite resources with 4 custom
  resources skipped, 14 valid OpenBao resources, 25 valid External Secrets resources
  with 25 CRDs skipped, and 3 valid runtime-store resources with 1 custom resource
  skipped. A separate pass validated all 5 selected Certificate, Issuer, and
  ClusterSecretStore resources against schemas extracted from the pinned CRDs with no
  invalid, errored, or skipped objects.
- Phase-specific assertions confirmed three OpenBao Raft voters, two retained PVCs per
  voter, TLS, a persistent file audit device, digest-pinned images, hardened
  containers, three two-replica ESO controllers, bounded TokenRequest RBAC, and an
  audience-bound Kubernetes-auth store. Kube-linter reported no findings.
- `make lint` returned exit 0. Markdownlint checked 78 files with no issues; ShellCheck
  and yamllint returned no findings; ansible-lint again reported zero failures and
  warnings across 28 processed files.
- The staged `make validate` returned exit 0 across every Phase 1–6 gate and repository
  policy check. The final generic kubeconform pass validated 25 resources from 17 files
  with no invalid, errored, or skipped objects, and kube-linter reported no findings.
- `make security` returned exit 0. Gitleaks scanned approximately 431 KB of the staged
  working tree and 2.39 MB across 14 existing commits, finding no leaks.
- The skeptical review removed unsupported object-name fields from the AppProject
  cluster-resource allowlist; Argo CD supports group/kind allowlisting there, while the
  exact repository and destination namespaces provide the remaining boundary. It also
  added required pod anti-affinity, `AlwaysAllow` unhealthy-pod eviction policy, and an
  explicit OpenBao auth-delegator setting.
- The OpenBao chart exposes active and standby Services using runtime labels that do
  not exist in a static StatefulSet render. Only its `dangling-service` kube-linter
  check is excluded as a documented false positive; all other checks remain enabled.
- The SOPS/OpenBao ADR keeps only circular bootstrap dependencies in SOPS. No fake
  `ExternalSecret` or runtime value was added: real namespaced stores and consumers are
  introduced with the workloads that own them.
- No cluster, secret service, account, or Git remote was modified. Initialization,
  manual unseal, Raft election, audit persistence, Kubernetes authentication, secret
  refresh, rotation, revocation, and break-glass recovery remain `PENDING HARDWARE`.

## Phase 7 validation — 2026-10-12

- Phase 7 was committed as `2a6197b` before the progress ledger, full repository gate,
  and skeptical review were complete. The repair commit preserves history and adds the
  missing evidence, corrects the OpenBao monitor port and monitoring ingress boundary,
  and replaces Sloth's chart-provided wildcard RBAC.
- Official chart archives matched the pinned SHA-256 values for
  kube-prometheus-stack `92.3.0`, Prometheus Blackbox Exporter `11.20.0`, Loki `7.3.0`,
  Alloy `1.13.1`, Tempo `1.24.4`, OpenTelemetry Collector `0.175.1`, and Sloth `0.16.0`.
  Every rendered Phase 7 workload image is pinned by OCI digest.
- `make validate-observability` returned exit 0. Seven Helm charts linted with no
  failures, and two independently produced renders of each component compared
  byte-for-byte equal.
- Strict built-in kubeconform passes reported 1 valid bootstrap resource; 3 valid and
  4 custom runtime-secret resources; 66 valid and 53 custom kube-prometheus-stack
  resources; 6 valid blackbox resources; 9 valid Loki resources; 8 valid and 1 custom
  Alloy resources; 4 valid and 1 custom Tempo resources; 6 valid and 1 custom OTel
  resources; 4 valid and 2 custom Sloth resources; 3 valid and 8 custom repository
  resources; and 3 valid and 2 custom notification resources. A separate strict pass
  validated all 61 selected custom resources against schemas extracted from pinned
  CRDs with zero invalid, errored, or skipped objects.
- `promtool check rules` reported success for 10 repository-authored alerting rules.
  The validator also parsed all 7 dashboard JSON documents and matched every alert's
  `runbook_url` fragment to a real runbook heading.
- Workload assertions found no missing requests, limits, probes, digest pins, dropped
  capabilities, read-only root filesystem, or privilege-escalation denial. Kube-linter
  reported no findings across the Phase 7 outputs, with only the documented upstream
  node-exporter host-access and operator-created Service exceptions excluded.
- Source review of Sloth `v0.16.0` found only list/watch access to
  `PrometheusServiceLevel`, status updates, and create/get/update access to generated
  `PrometheusRule` objects. The renderer replaces the chart's wildcard ClusterRole
  with those exact permissions, and the validator rejects wildcard resources or verbs.
- `make lint` returned exit 0 after the review fixes. Markdownlint checked 92 files
  with no issues, yamllint and ShellCheck reported no findings, and ansible-lint again
  reported zero failures and warnings across 28 processed files.
- `make validate` returned exit 0 across every Phase 1–7 gate and repository policy
  check. The final generic kubeconform pass validated 25 resources from 17 files with
  no invalid, errored, or skipped objects, and kube-linter reported no findings.
- `make security` returned exit 0. Gitleaks scanned approximately 529 KB of the working
  tree and 2.54 MB across 17 commits, finding no leaks.
- The Tempo chart prints an upstream deprecation warning. The pinned chart remains
  validated for this phase, but migration to a supported Tempo chart is an upgrade
  item and is not represented as resolved.
- No cluster or external notification endpoint was contacted. Scrape discovery,
  ingestion, retention under real load, dashboard queries, SLO rule generation,
  blackbox checks, and notification delivery remain `PENDING HARDWARE`.

## Phase 8 validation — 2026-10-12

- Official chart archives matched the recorded SHA-256 values for Kyverno `3.9.1`
  (application `v1.19.1`) and Trivy Operator `0.37.0` (application `0.35.0`).
  Controller, scanner, checks, and readiness-checker images use the immutable OCI
  digests recorded in `policies/dependencies.env`.
- `make validate-policy` returned exit 0. Helm lint reported one chart and zero
  failures for both Kyverno and Trivy Operator, and two independent renders of every
  Phase 8 component compared byte-for-byte equal.
- Strict built-in kubeconform passes reported 2 valid namespace resources; 57 valid
  Kyverno built-ins with 26 custom resources skipped; 17 valid Trivy built-ins with
  17 custom resources skipped; 8 audit and 8 enforcement custom resources skipped;
  and 3 valid posture resources with 1 custom resource skipped. Separate schema passes
  validated 4 Kyverno, 5 Trivy, 8 audit, 8 enforcement, and 1 posture custom resources
  with no invalid, errored, or skipped objects.
- `kyverno test` reported all 10 expected CEL policy outcomes as passing. The valid
  fixture passed five baseline controls and the intentionally invalid fixture failed
  the same five controls as expected. The intentionally invalid image tag is excluded
  only from the repository pin scanner's fixture path.
- `promtool check rules` reported success for the critical-vulnerability alerting
  rule. The security dashboard parsed as valid JSON, workload and digest assertions
  passed, namespace PSA label assertions passed, and kube-linter reported no findings.
- The audit and enforcement overlays render from the same policy sources. Six
  `policies.kyverno.io/v1` CEL validating policies and one CEL image-verification
  policy move from `Audit` to `Deny` through explicit patches. The NetworkPolicy
  inventory rule remains a legacy `ClusterPolicy` because the pinned CEL API has no
  API-call context; this migration debt is documented before Kyverno 1.20.
- `make validate-gitops` returned exit 0 after adding the five Phase 8 applications
  and restricted policy project. Its GitOps resource pass reported 45 valid objects
  with no errors or skips, and kube-linter reported no findings.
- `make lint` returned exit 0. Markdownlint checked 105 files with no issues;
  yamllint and ShellCheck reported no findings; ansible-lint again reported zero
  failures and warnings across 28 processed files.
- The staged `make validate` returned exit 0 across every Phase 1–8 gate and repository
  policy check. The final generic kubeconform pass validated 25 resources from 17 files
  with no invalid, errored, or skipped objects, and kube-linter reported no findings.
- `make security` returned exit 0. Gitleaks scanned approximately 602 KB of the staged
  working tree and 2.55 MB across 18 existing commits, finding no leaks.
- The skeptical review repaired earlier namespace manifests with explicit PSA
  `enforce`, `audit`, and `warn` labels pinned to Kubernetes `v1.36`. It also made the
  whoami NetworkPolicy precede its workload and documented required infrastructure
  exceptions instead of claiming privileged controllers satisfy application policy.
- Trivy node collection and infrastructure assessment are deliberately disabled;
  kube-bench remains a documented human-run node check, and Kubescape is not installed
  because its controls overlap the selected Kyverno/Trivy/PSA stack.
- No cluster, registry, transparency log, or Git remote was contacted. Admission and
  background reports, Trivy scan jobs and metrics, keyless signature verification,
  audit latency, exception handling, and the eventual Audit-to-Deny promotion remain
  `PENDING HARDWARE`.

## Phase 9 validation — 2026-10-13

- Repaired the partial Sentinel work forward without rewriting its existing commits.
  Removed the two GitHub Actions workflows because GitLab is the specified CI and
  delivery authority; GitHub remains a source mirror.
- Implemented separate Go API and probe-worker binaries, embedded migrations and UI,
  PostgreSQL transition storage, read-only public status output, Prometheus metrics,
  OpenTelemetry, health/readiness endpoints, and unit tests. `make -C apps/sentinel
  lint test build` returned exit 0; the race-enabled tests reported 76.7% API, 64.1%
  configuration, and 68.2% probe coverage.
- `scripts/test-sentinel-integration.sh` returned exit 0 against disposable pinned
  PostgreSQL `17.6`. It applied the real migration, verified the first observation
  creates a transition, verified a repeat does not, and read the public status back.
- The integration test exposed an invalid earlier CloudNativePG PostgreSQL image
  digest. OCI inspection of the same `17.6-system-trixie` tag reported index digest
  `sha256:6ae4a22c14bdc66e5feaafd38d12c3956fabf9ce9582189e6aa4ee767d981d1b`;
  Phase 5 was repaired to use it and `make validate-storage` returned exit 0.
- Local Docker Buildx produced deterministic multi-platform OCI indexes after the
  Dockerfiles were corrected to run the compiler on `$BUILDPLATFORM`: API digest
  `sha256:2d44b692b61e05a8393bdee5229cf8242e89d729a6090f0d431064eb2a6ab495`
  and worker digest
  `sha256:2403b35fe59bcc0d05763f521983d5d2e7e1afe7531536166d125f750841db0d`.
  These local indexes were not pushed and are placeholders until GitLab builds its own
  signed release digests.
- Pinned Syft `v1.54.0` generated SPDX JSON documents for both local OCI indexes.
  Pinned Trivy `0.75.0` scanned their extracted OCI layouts with the downloaded
  vulnerability database and reported zero high or critical Debian or Go findings for
  both images. Keyless signing cannot be exercised locally without the protected CI
  identity and registry.
- GitLab CI now builds one `linux/amd64,linux/arm64` index per binary, emits SPDX SBOMs,
  gates high and critical Trivy findings, signs and attests GitLab registry digests with
  OIDC, automatically commits the staging digest lock, and requires manual production
  approval. It mirrors the identical API and worker indexes plus an unrendered
  deployment bundle to three GHCR packages and signs each GHCR digest. The pipeline has
  not run remotely and no package was pushed during repository validation.
- Implemented pinned Argo Rollouts, staging and production Kustomize overlays,
  environment-specific image locks, canary analysis, HPA, PDB, topology spread,
  CloudNativePG with Barman backups, External Secrets/OpenBao policies, three network
  policies, ServiceMonitors, alerting, dashboard, and a Sloth SLO. Production publishes
  only the status route; staging uses the internal Gateway.
- `scripts/validate-sentinel.sh` returned exit 0. The Argo Rollouts chart linted with
  zero failures; two renders of every dependency and both application overlays were
  byte-identical. Built-in kubeconform passes had no invalid resources. Strict pinned
  schemas validated 13 custom resources in each overlay with no invalid, errored, or
  skipped objects. Promtool accepted both rule sets, dashboard JSON parsed, k6 parsed
  the bounded status scenario, kube-linter found no errors, and Go vet/test/build
  passed.
- `make validate-gitops`, `make validate-edge`, and `make validate-secrets` returned
  exit 0 after adding the Rollouts project, Sentinel applications, public status DNS
  and Tunnel route, and runtime-secret policies. The OpenTofu offline plan reported
  five resources to add and no changes or destroys.
- Skeptical review corrected the registry path used by Kubernetes, changed the
  single-replica staging PDB to permit one unavailable pod, added the missing
  SecretStore AppProject permission, and made registry authentication explicit for
  Syft, Trivy, Cosign, and ORAS jobs. It also replaced the public catch-all route with
  four exact UI/status paths so health and metrics endpoints remain private.
- `make lint` returned exit 0. Markdownlint checked 111 files with no issues;
  yamllint and ShellCheck reported no findings; ansible-lint reported zero failures
  and warnings across 28 processed files.
- The final `make validate` returned exit 0 across every Phase 1–9 gate and the
  repository file, private-value, dependency-pin, generic kubeconform, and kube-linter
  checks. The final generic pass validated 25 resources with no errors or skips.
- `make security` returned exit 0. Gitleaks scanned approximately 720 KB of the working
  tree and 3.35 MB across all 28 existing commits and found no leaks.

## Phase 10 validation — 2026-10-13

- Repaired the prematurely tracked Phase 10 sources forward. Several purpose-named
  files contained concatenated resources that belonged in neighboring manifests; the
  repair restored one concern per file without rewriting history.
- `make phase10-deps` returned exit 0. OCI index inspection matched the recorded
  digests for Keycloak `26.8.0`, Vaultwarden `1.37.4-alpine`, Homepage `v2.5.0`, and
  rootless Uptime Kuma `2.5.5`. Image configuration inspection confirmed Keycloak UID
  1000 and Uptime Kuma's `node` user; local container inspection confirmed Homepage's
  UID 1000 runtime and Vaultwarden's root-owned binary, which is deliberately launched
  as UID/GID 65534 with volume ownership supplied by `fsGroup`.
- Implemented a two-replica Keycloak service backed by a three-instance CNPG cluster,
  Barman WAL/data backups, an internal-only route, health/metrics probes, a PDB,
  topology controls, monitoring, and default-deny network boundaries. The declarative
  realm defines Argo CD and Grafana clients, group claims, and default TOTP enrollment
  for every account. Local Argo CD and Grafana credentials remain available for private
  break-glass recovery.
- Added Vaultwarden with a three-instance CNPG database and Barman backups, stateless
  Homepage configuration, and rootless Uptime Kuma. Every application image is pinned
  by digest; every Deployment has requests/limits, probes, restricted security
  contexts, a NetworkPolicy, a PDB, an internal Gateway route, and an availability
  alert. Longhorn data is included by the existing daily Velero schedule. Sentinel
  remains the only selected-service public status page.
- `make validate-identity-apps` returned exit 0. Two renders of Keycloak and all three
  application overlays were byte-identical. Built-in kubeconform passes had no invalid
  objects. Pinned CRD schemas validated 10 Keycloak, 9 Vaultwarden, 2 Homepage, and 2
  Uptime Kuma custom resources with no invalid, errored, or skipped objects. Promtool
  accepted all four rule sets, realm JSON and group mappers parsed, and kube-linter
  reported no findings.
- The validation gate asserts two Keycloak replicas, three instances in both CNPG
  clusters, immutable workload images, full container resources/probes/hardening, a
  NetworkPolicy for every Deployment, PVC coverage, and internal-only HTTPRoutes.
- `make lint` returned exit 0. Markdownlint checked 119 files with no issues;
  yamllint and ShellCheck reported no findings; ansible-lint reported zero failures
  and warnings across 28 processed files.
- The final `make validate` returned exit 0 across every Phase 1–10 gate and the
  repository policy checks. The final generic kubeconform pass validated 25 resources
  from 17 files with no invalid, errored, or skipped objects, and kube-linter reported
  no findings.
- `make security` returned exit 0. Gitleaks scanned approximately 791 KB of the working
  tree and 3.55 MB across all 30 existing commits and found no leaks.
- Skeptical review fixed central-config interpolation for Argo CD's secret reference
  and Grafana's OIDC URLs, added missing anti-affinity and unhealthy-pod eviction
  behavior, kept all administration surfaces private, and documented capacity and SSO
  recovery boundaries. No account, cluster, registry, or cloud service was modified.

## Phase 11 validation — 2026-10-13

- The official Chaos Mesh `2.8.4` chart archive matched SHA-256
  `ae4abd385649771300e4d33a44627c0df3618be0780c385bf30cc2fdf2ad93fa`.
  `helm show chart` reported chart and application version `2.8.4`; `helm show values`
  confirmed the k3s containerd socket and namespace-filter fields used by the values.
- Implemented three HA controller replicas, one privileged daemon per node, disabled
  dashboard/DNS/profiling, cert-manager webhook certificates, controller resource and
  security hardening, probes, PDBs, and namespace NetworkPolicies. The necessary
  daemon host/runtime privilege is documented as a narrow infrastructure exception.
- Only `chaos-testing` has `chaos-mesh.org/inject=enabled`. The GitOps application
  contains the controller and sacrificial three-replica target but no experiment CRs.
  `make test-chaos` without `CONFIRM_CHAOS=homelab` returned exit 2 before any
  Kubernetes command; the confirmed script also refuses when another namespace opts in.
- Added four purpose-named experiment files: one bounded pod kill, delay and partition
  network cases, bounded CPU stress, and bounded filesystem latency. Every selector and
  target is pinned to `chaos-testing` and the explicit sacrificial workload label.
- `make validate-chaos-dr` returned exit 0. Two controller renders and two experiment
  renders compared byte-for-byte equal. The chart linted with zero failures. Generic
  kubeconform reported 57 resources with no invalid objects or errors; pinned Chaos
  Mesh schemas validated all five experiment CRs, and pinned cert-manager schemas
  validated all six generated Certificate/Issuer resources. Kube-linter reported no
  findings after only the documented chaos-daemon privilege checks were excluded.
- Offline rendering caught the upstream chart selecting obsolete cert-manager
  `v1alpha2` when discovery data was absent. The renderer now declares the installed
  `cert-manager.io/v1` API explicitly, and the resulting objects passed strict schema
  validation.
- Added bounded baseline and ten-minute sustained k6 scenarios for Sentinel. `k6
  inspect` parsed every load script successfully; none was executed against a live
  endpoint.
- Authored seven separate DR drills for node power loss, quorum recovery, etcd S3
  restore, PostgreSQL failover/PITR, Velero namespace restore, single-node rebuild, and
  full bare-metal rebuild. Each has preconditions, procedure, rollback, expected
  behavior, `PENDING HARDWARE` status, and an intentionally empty results table.
- `make validate-gitops` returned exit 0 with 52 strict custom resources and no errors
  or skips after adding the restricted resilience project and sync-wave-30 application.
  `make validate-policy` returned exit 0 after the privileged namespace received an
  explicit PSA version.
- `make lint` returned exit 0. Markdownlint checked 128 files with no issues;
  yamllint and ShellCheck reported no findings, and ansible-lint reported zero failures
  and warnings across 28 processed files.
- The final `make validate` returned exit 0 across every Phase 1–11 gate, dependency
  pin and private-value checks, generic kubeconform, and kube-linter.
- `make security` returned exit 0. Gitleaks scanned approximately 839 KB of the working
  tree and 3.58 MB across all 32 existing commits and found no leaks.

## Phase 12 validation — 2026-10-13

- Replaced the root overview with an 84-line recruiter-focused README and added the
  MIT license, single-owner CODEOWNERS, concise security policy, compatibility matrix,
  evidence map, complete ADR/runbook indexes, upgrade guide, alert index, experimental
  phone-worker boundary, and exact screenshot checklist.
- Expanded the architecture document to nine Mermaid diagrams covering physical,
  network, GitOps, delivery, secret, observability, storage, identity, and resilience
  flows. The public-surface and skills documents now link directly to their evidence.
- Skeptical review found that the Argo CD renderer silently relied on ignored local
  chart caches. The repair gives every fetcher an overridable cache root, installs curl
  from the immutable `curlimages/curl:8.16.0` image, checksum-verifies dependencies,
  serializes cache population with `flock`, and renders from the repo-server's writable
  temporary volume. No chart archive or rendered private value is committed.
- A clean temporary-cache render downloaded the corrected external-dns `1.22.0`
  release, created the verified marker, and two renders produced the same SHA-256
  `2b1e6da164f7016b85009b30ef6d7120b304009f166c8911c97e64291c3e69e8`.
- `make validate-portfolio` returned exit 0. It checked required governance/evidence
  files, the README line budget, architecture coverage, unique ADR numbers, alert
  runbook links, prohibited contributor files, and the public Make interface.
- The final `make validate` returned exit 0 across every Phase 1–12 gate. It rebuilt
  the Phase 2–11 dependency caches from pinned sources, verified checksums, completed
  all deterministic render/schema/policy/application checks, and finished with 25
  generic resources valid and no kube-linter findings.
- `make security` returned exit 0. Gitleaks scanned approximately 855 KB of the working
  tree and 3.62 MB across all 33 existing commits and found no leaks.
- No node, cluster, cloud account, registry, Git remote, or public endpoint was changed.

## GitLab CI repair — 2026-10-13

- The first pipeline after publishing the completed repository failed before creating
  jobs. GitLab's CI linter reported that the inherited Sentinel promotion scripts were
  not strings because YAML interpreted an unquoted colon followed by a space in the
  commit message as a mapping.
- Quoted the complete promotion command and added a local regression assertion that
  every `script`, `before_script`, and `after_script` entry is a YAML string.
- GitLab's project CI lint API then returned `valid: true` with no errors or warnings.
  `make validate-sentinel`, `make lint`, and `make security` also returned exit 0;
  Gitleaks found no leaks in the working tree or all 34 commits.

## GitHub application packages — 2026-10-13

- Added a repository-token and OIDC-based GitHub workflow that publishes separate
  deployment-source OCI packages for Homepage, Keycloak, Sentinel, Uptime Kuma,
  Vaultwarden, and whoami. Actions are commit-pinned, ORAS is checksum-verified, and
  every immutable digest is signed with Cosign.
- The first live run reached authenticated GHCR publication but failed because ORAS
  rejects absolute layer paths. The repair packages reproducible archives in the
  runner temporary directory and presents only relative layer names to ORAS.
- [GitHub Actions run 38462751656](https://github.com/AnouarMohamed/kubernetes-homelab/actions/runs/38462751656)
  completed all six jobs successfully, including package publication and keyless
  signing. The recorded manifest digests begin `2ad12737` (Keycloak), `da39c8b9`
  (Homepage), `d1494b4f` (Vaultwarden), `afee6cf5` (Sentinel), `28bda5ed` (whoami),
  and `168440a5` (Uptime Kuma).
- `make validate-ghcr-packages`, `actionlint`, `make lint`, the pin check, portfolio
  validation, and `make security` returned exit 0. The final secret scan covered all
  36 commits and found no leaks.

## Unverified

- All real-hardware behavior.
- Every dependency not yet listed with upstream evidence in `PLAN.md`.
- Live execution of the GitLab pipeline on a protected, privileged runner.
- Publication and keyless verification of the GitLab-built Sentinel image mirrors
  remain pending. GitHub published and signed the six deployment-source packages, but
  their public visibility still requires the documented package-settings review.
- Compatibility of the selected S3 service with Longhorn, Barman Cloud, and Velero.
- OpenBao HCL startup and the declarative audit device on the real cluster.
- Phase 7 signal ingestion, storage sizing, scrape selectors, alert delivery, and the
  pinned deprecated Tempo chart's behavior on the real cluster.
- Kyverno and Trivy Operator runtime compatibility with k3s `v1.36.5+k3s1`, policy
  report generation, admission latency, scanner execution, metrics freshness, and
  GitLab OIDC signature verification against the transparency log.
- Sentinel canary analysis, HPA behavior, CloudNativePG failover and recovery, S3
  backups, public routing, probe accuracy, alert delivery, and k6 execution against a
  deployed environment.
- Keycloak realm import, TOTP enrollment, group claims, Argo CD/Grafana login and local
  recovery, CNPG failover/backups, Vaultwarden's non-root volume permissions, Homepage
  startup with a read-only root filesystem, Uptime Kuma persistence, and Velero restore
  remain `PENDING HARDWARE`.
- Chaos Mesh controller/daemon behavior on k3s, namespace-filter enforcement, every
  experiment, both k6 scenarios, and all seven DR drills remain `PENDING HARDWARE`.
- Argo CD repo-server dependency downloads, cache reuse, and reconciliation remain
  `PENDING HARDWARE`; offline validation exercised the same scripts but not the pod.
- Phase 12 screenshots, live-link evidence, and recruiter walkthrough remain
  `PENDING HARDWARE` until the platform is deployed and identifying data is redacted.

## Not done

- No real node, cluster, Cloudflare account, or S3 service was modified. The completed
  repository and package workflow were pushed to the GitLab and GitHub remotes.
- Vendor-specific S3 bucket provisioning is not implemented because the service has
  not been selected; creating and versioning the bucket is a documented human task.
- Automatic OpenBao unseal is intentionally not implemented because no external KMS or
  HSM has been selected; the manual Shamir boundary is documented and pending exercise.
- Phase 8 enforcement is intentionally not enabled before Anouar reviews real audit
  reports. Kubescape is deliberately omitted, and kube-bench has not been run because
  node execution is hardware-only.
- The Sentinel GitLab build, digest-promotion commits, image mirrors, GitLab OIDC
  signatures, and live k6 scenario have not run because they require Anouar's
  protected runner variables and cluster. The separate GitHub deployment bundles did
  publish and sign successfully.
- Phase 10 OpenBao values and initial identity accounts were not created because they
  require Anouar's recovery material and private administration session.
- No chaos experiment, load scenario, power operation, restore, rebuild, or destructive
  recovery command was run. Result tables remain empty by design.
