# Homelab Build Plan

## Intent

I am building one specific three-node homelab, not a reusable starter template. The
repository is both the desired state of the platform and the evidence behind every
portfolio claim. Existing commits remain in history; Phases 0–3 are repaired forward
before later phases begin.

## Final repository tree

```text
.
├── AGENTS.md
├── PLAN.md
├── PROGRESS.md
├── HUMAN_TODO.md
├── README.md
├── Makefile
├── config/homelab.yaml
├── docs/
│   ├── BUILD_SPEC.md
│   ├── STATUS.md
│   ├── VERIFY_ON_HARDWARE.md
│   ├── architecture.md
│   ├── adr/
│   ├── dr/
│   ├── img/
│   ├── incidents/
│   ├── journal/
│   ├── runbooks/
│   └── security/
├── infra/
│   ├── ansible/
│   └── tofu/
├── clusters/homelab/
│   ├── bootstrap/
│   ├── projects/
│   ├── apps/
│   └── root-app.yaml
├── platform/
├── observability/
├── policies/
├── apps/
│   ├── sentinel/
│   ├── keycloak/
│   ├── vaultwarden/
│   ├── homepage/
│   └── uptime-kuma/
├── ci/
├── scripts/
├── .gitlab-ci.yml
├── renovate.json
├── .pre-commit-config.yaml
├── .sops.yaml
└── .yamllint
```

## Repository conventions

- Hand-authored YAML uses `.yaml`, not `.yml`.
- Manifest filenames describe purpose: `deploy-cilium.yaml`,
  `allocate-load-balancer-ips.yaml`, `restrict-platform-project.yaml`,
  `configure-cilium.yaml`, and `deny-ingress-by-default.yaml`.
- Tool-reserved or specification-mandated names remain unchanged, including
  `kustomization.yaml`, `Chart.yaml`, and `root-app.yaml`.
- `config/homelab.yaml` is the sole checked-in source of environment-specific domain,
  node, LAN, S3, GitLab, and timezone values. Ansible and OpenTofu parse it directly.
  A pinned Argo CD config-management plugin renders Kustomize inputs in memory; private
  values never appear in generated files in Git.
- Runtime secrets come from OpenBao. SOPS and age are limited to bootstrap material.
- GitLab is the CI, registry, and Argo source. GitHub is a public mirror.
- Every validation result is summarized in `PROGRESS.md`; hardware checks are never
  marked passed by automation.

## Verified version baseline

| Component | Pin | Verification |
| --- | --- | --- |
| k3s | `v1.36.5+k3s1` | Official release checksum for amd64 binary: `d73847bcd3c5fccef0115b372e2f9a91f3032dc84bbf71518a4617565294d313` |
| kube-vip | `v1.2.4` | OCI index digest `sha256:dde4c0669d9058c74c69c0bc2f0122e26900e1e4b913c03577cb6e4e28083079` |
| Gateway API | `v1.6.1` standard channel | Release manifest SHA-256 `24d931f22abd8e40c973264319ead7cfa09d0fb7716b7ab1ee2ff174cb063a73` |
| Cilium chart | `1.20.2` | `helm show chart`; OCI digest `sha256:a7c12d330dd96bfcda3bf057b24be8f36566c34868265f930f776dff6f42d838` |
| Argo CD chart | `10.10.2` | `helm show chart`; app `v3.5.4`, OCI digest `sha256:96ff0d2150557ceb51c309c3adedb63455226c2dd2c5323f5b1e894536e2901d` |
| KSOPS | `v4.5.1` | Official release and image digest `sha256:4def9fdd4e2f850265740ebe9592c5455d19b76891e88e602df8b52d74b95334` |
| community.general | `13.4.0` | Galaxy artifact SHA-256 `efd1c0b5dc6f89b9667e4bd77f2426c30545861910dba188593871095ede1804` |
| cert-manager chart | `v1.21.1` | Official OCI digest `sha256:15c0b46d9006ce8eb9ff14d1bf54d1bbfcc587bb9e24cd9fe186fb8fec56af1f` |
| external-dns chart | `1.22.0` | Official release archive SHA-256 `ec26bba67e02f46a55ac33790ad9d9ded724a163af6f6b4a63ce68f883201f4f`; app `0.22.0` |
| Cloudflare provider | `5.27.0` | Exact official OpenTofu provider constraint and dependency lock |
| cloudflared | `2026.10.0` | OCI digest `sha256:9b49eed8f62806d5d45ddf59ecefb5710429598ea6d3fcccd2af938f621b2b07` |
| whoami | `v1.11.0` | OCI digest `sha256:200689790a0a0ea48ca45992e0450bc26ccab5307375b41c84dfc4f2475937ab` |
| external-snapshotter | `v8.6.0` | Five official manifests are checksum-pinned; controller OCI digest `sha256:0d01d2b374e36437781aa0264809aeacec842b0f378556582601106eff503753` |
| Longhorn chart | `1.12.1` | Official stable release archive SHA-256 `c8cf4b35a9d872cd5f7e44fd26d8e6ac7c2abaee42f4e2f2a0b0ebbc6e3a6116` |
| CloudNativePG chart | `0.29.1` | Official archive SHA-256 `b53d3991fe84bcf38767e7702cae78666265427a127a26fff168ab4207d2b1df`; app `1.30.1` |
| Barman Cloud chart | `0.8.1` | Official archive SHA-256 `9ad0b9e56da2777a1a0269feaf7215e18297e9c8b5730e04acb27b5d462e9456`; app `v0.15.1` |
| Velero chart | `12.2.1` | Official archive SHA-256 `fe4acd70a0123c369e7af7064457b4ffdddebee413e2bb01976a4fe07c471773`; app `1.18.2` |
| Velero AWS plugin | `v1.14.4` | OCI digest `sha256:e6d328cefcdccecea23510ce361f8979e80a91386a99f21b0055e554259a35ec` |
| OpenBao chart | `0.30.3` | Official release archive SHA-256 `d50ed31b8305f430df308c342dd3c1efa877222380e99cb480f74f070d6beaa8`; app `v2.7.1` |
| OpenBao | `2.7.1` | OCI index digest `sha256:6d2b93856e3fcf7b18ad855a0b51eaba474dc8b79cf554379ea32034797d2acf` |
| External Secrets chart | `2.12.0` | Official release archive SHA-256 `4b584136b7311c0af8c8719d377cc5b1a7ef12c2de18f1fdb30614eab75bdeb3`; app `v2.12.0` |
| External Secrets | `v2.12.0` | OCI index digest `sha256:7a3c4f7e038fa0f86a3172da19b9388f3f4d846e87e9994ee3474c5b72a9330d` |
| kube-prometheus-stack chart | `92.3.0` | Official release archive SHA-256 `48399b911fa91b353e0c3d5e32c1cb7a67a168566549723553154ffd7be5d1fa`; app `v0.94.1` |
| Prometheus blackbox exporter chart | `11.20.0` | Official release archive SHA-256 `e341b17f202c7ff95cae056d23a481d8080aa3dc1dbaaa5d68296595b8b90ace`; app `v0.29.0` |
| Loki chart | `7.3.0` | Official release archive SHA-256 `04a339f712d770a1f599f05fc0a5a3cde18e43914e49ae6a49f7171be86bcc09`; app `3.6.12` |
| Alloy chart | `1.13.1` | Official release archive SHA-256 `6c2b7df23e39438bb11f1e1fcf19eb9eb7c8bfeab7d49b7c975b6212abd0f99a`; app `v1.20.1` |
| Tempo chart | `1.24.4` | Official release archive SHA-256 `f1f6e318d5bca3b5097cb676077796cdf8135beb2c1f71c4d14614ccf9b0081b`; app `2.9.0` |
| OpenTelemetry Collector chart | `0.175.1` | Official release archive SHA-256 `33996399f5d831193603f8a56ed46b7cd3f012eeb6df4d5046c5b560a554e21d`; app `0.161.0` |
| Sloth chart | `0.16.0` | Official release archive SHA-256 `616acb580eefc2e9836cc1b430cac6d424e0e4210130786b6ec883657217c6db` |
| Kyverno chart | `3.9.1` | Official chart index archive SHA-256 `7b7fe51a431b5b133b0ce7eb9dcb222b6a37fb967c163223cf480054ad14d752`; app `v1.19.1` |
| Trivy Operator chart | `0.37.0` | Official Aqua chart index archive SHA-256 `6d23f16d950496d17253258ca2e52bd068959041298e66c0652bf0841ccedf69`; app `0.35.0` |

All remaining later-phase chart, provider, collection, application image, and CI image
versions are `VERIFY`. Before implementing their phase I will verify them against an
official chart index, release, registry, or `helm show chart/values`, replace `VERIFY`
with an exact pin, and record the evidence. An unverified dependency is not eligible
for a completed phase.

## Phase plan

### Phase 0 — Skeleton and CI

Files: root controls and configuration; documentation skeleton; component READMEs;
tool installer; CI, pre-commit, Renovate, SOPS, YAML, Markdown, and Ansible-lint config.

Validation: `make tools`, `make lint`, `make validate`, secret-path guard, private-value
guard, pin guard, `gitleaks git --log-opts=--all`.

Risks: public secret leakage, validators silently skipping files, mutable CI images,
and bootstrap configuration drifting from manifests.

### Phase 1 — Nodes and k3s

Files: Ansible inventory template, requirements, base/hardening/k3s/kube-vip roles,
ordered site/upgrade/reset playbooks, CIS table, firewall table, upgrade and replacement
runbooks.

Validation: `ansible-lint`, three syntax checks, and static idempotence review. Real
convergence, re-run, reboot, quorum, VIP, and snapshot checks are PENDING HARDWARE.

Risks: locking out SSH, joining through the VIP before it exists, expecting Ready nodes
before CNI, insufficient firewall rules, and destructive reset misuse.

### Phase 2 — Cilium

Files: pinned Gateway API CRDs, verified Cilium values, LB IP pool and announcement
policy, baseline NetworkPolicy component, bootstrap script, ADR, and runbook.

Validation: Helm template/lint, kubeconform with CRD schemas, kube-linter, deterministic
render comparison. Connectivity and L2 failover are PENDING HARDWARE.

Risks: API/Cilium incompatibility, invalid L2 selectors, incorrect interface regex,
under-sized Kubernetes client rate limits, and firewall conflicts.

### Phase 3 — Argo CD

Files: Helm values, config-management plugin image, KSOPS generator, root app,
restricted projects, component Applications, ApplicationSet, RBAC, recovery and sync
wave runbooks, and credential ADR.

Validation: chart render, Kustomize/CMP render, schema validation, project boundary
tests, and two identical renders. Sync and self-heal are PENDING HARDWARE.

Risks: bootstrap circular dependency, excessive project permissions, repository secret
exposure, and Argo managing a different Cilium configuration from bootstrap.

### Phase 4 — Certificates, DNS, and access

Files: Cloudflare OpenTofu modules; cert-manager, external-dns, cloudflared, Gateway,
HTTPRoute, and whoami resources; WARP/split-DNS docs; traffic diagram and ADR.

Validation: Tofu fmt/validate, chart rendering, schema/policy checks. DNS, ACME, tunnel,
and WARP checks are PENDING HARDWARE/ACCOUNT.

Risks: overly scoped Cloudflare tokens, state leakage, DNS loops, and accidental public
exposure of administration endpoints.

### Phase 5 — Storage and backups

Files: Longhorn, CNPG, and Velero configuration; S3 OpenTofu; reschedule test; storage
restore drill and runbooks.

Validation: chart/schema/policy validation and script linting. Replication, backups,
restore, and reschedule tests are PENDING HARDWARE.

Risks: insufficient disks, correlated replicas, S3 credential mistakes, and backups
that have never been restored.

### Phase 6 — Runtime secrets

Files: OpenBao and External Secrets configuration, auth/policy setup jobs, secret store,
bootstrap boundary ADR, and unseal/rotation/break-glass runbooks.

Validation: chart/schema/policy checks and declarative configuration tests. Initialization,
unseal, rotation, and recovery are PENDING HARDWARE.

Risks: unseal-key loss, circular secret dependencies, audit-log loss, and over-broad
namespace policies.

### Phase 7 — Observability

Files: Prometheus stack, Loki, Alloy, Tempo, OTel Collector, blackbox exporter,
dashboards, rules, SLOs, Alertmanager, notifications, and runbooks.

Validation: Helm/schema/policy checks, `promtool check rules`, dashboard JSON parsing,
and runbook-link validation. Signal delivery is PENDING HARDWARE.

Risks: resource pressure, cardinality growth, retention exceeding disk capacity, and
alerts without actionable ownership.

### Phase 8 — Policy and supply chain

Files: Kyverno policies/tests/exceptions, PSA namespace configuration, Trivy Operator,
security dashboards, threat model, posture summary, and enforcement rollout plan.

Validation: `kyverno test`, deterministic Helm/Kustomize rendering, strict pinned CRD
schemas, Audit and Deny overlay assertions, Trivy config render, Prometheus rule and
dashboard parsing, workload checks, PSA-label coverage, and kube-linter.

Risks: breaking required infrastructure privileges, policy bypass through broad
exceptions, enabling enforcement before existing resources comply, and the one legacy
API-context policy that must be migrated before Kyverno 1.20.

### Phase 9 — Homelab Sentinel and delivery

Files: Go probe worker/API/UI, migrations, tests, Dockerfile, CI templates, CNPG cluster,
Kustomize base/overlays, Rollout/analysis/HPA/PDB/policies/monitoring/SLO/dashboard,
release and rollback runbooks, and image-promotion ADR.

Validation: Go format/vet/test/race, migration tests, container build, SBOM, Trivy,
Cosign verification, manifest render/schema/policy checks, and k6 smoke test.

Risks: probe abuse, false incidents, database migration failure, unsigned promotion,
and public leakage of internal service details.

Demo options considered:

1. **Homelab Sentinel — chosen.** It checks my own public services, records transitions,
   exports metrics/traces, and feeds the public status page. It is small, operationally
   useful, and easy to explain in an interview.
2. Backup catalog explorer — rejected because browsing backups is less useful publicly
   and increases the chance of metadata disclosure.
3. Vulnerability posture dashboard — rejected because Trivy/Grafana already cover the
   need and a second presentation layer would be redundant.

### Phase 10 — Identity and self-hosted apps

Files: Keycloak/CNPG/realm import, OIDC integrations, MFA/RBAC docs, Vaultwarden,
Homepage, Uptime Kuma, capacity budget, public status route, and SSO recovery runbook.

Validation: chart/schema/policy checks and configuration tests. Login, MFA, failover,
backup, and local recovery are PENDING HARDWARE.

Risks: SSO lockout, public admin surfaces, application-specific security-context
limitations, and exceeding node capacity.

### Phase 11 — Chaos and DR

Files: restricted Chaos Mesh installation, four experiments, k6 scenarios, and seven DR
drills with empty results tables.

Validation: manifest/schema/policy checks and k6 script parsing. Every experiment and
drill execution remains PENDING HARDWARE.

Risks: chaos escaping the test namespace, unclear abort criteria, destructive recovery
steps, and invented recovery-time claims.

### Phase 12 — Portfolio polish

Files: final README and diagrams, ADR/runbook indexes, evidence map, screenshot checklist,
SECURITY, LICENSE, CODEOWNERS, compatibility/upgrade guides, and phone-worker experiment.

Validation: all earlier gates, full-history gitleaks, dead-link/file checks, clean Git
status, README line budget, and claim-to-evidence audit.

Risks: documentation overstating untested behavior, stale compatibility claims, and
screenshots exposing private information.

## Assumptions and decisions

- I will repair forward and retain the weak initial commits as part of the history.
- No Git remote is pushed automatically.
- Cloudflare WARP's WireGuard-based client provides private administration without a
  raw inbound WireGuard listener; Cilium WireGuard still encrypts eligible cluster
  traffic.
- Keycloak is the identity provider.
- Homelab Sentinel is written in Go, uses CNPG, and does not use Redis.
- Infrastructure components that require host access or elevated capabilities receive
  narrow, documented policy exceptions; application workloads receive none.
- Empty DR/chaos result tables stay empty until Anouar performs the procedures.
- Missing human values never block repository work; they remain `CHANGE_ME_*` and are
  listed in `HUMAN_TODO.md`.

## Human TODO summary

- Replace all central configuration placeholders with the real domain, private network,
  S3, GitLab, and disk information.
- Generate and protect the age identity; commit only its public recipient and re-encrypt
  bootstrap placeholders.
- Create least-privilege Cloudflare, S3, GitLab deploy, and notification credentials.
- Initialize/unseal OpenBao and store recovery material offline.
- Run every command in `docs/VERIFY_ON_HARDWARE.md` and personally update verification
  status and DR result tables.
- Select any optional applications or experimental phone workers only after the core
  platform capacity report is available.
