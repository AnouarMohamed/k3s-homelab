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
| Gateway API | `v1.6.1` standard channel | Official Gateway API installation guide |
| Cilium chart | `1.20.2` | `helm show chart`; OCI digest `sha256:a7c12d330dd96bfcda3bf057b24be8f36566c34868265f930f776dff6f42d838` |
| Argo CD chart | `10.10.2` | `helm show chart`; app `v3.5.4`, OCI digest `sha256:96ff0d2150557ceb51c309c3adedb63455226c2dd2c5323f5b1e894536e2901d` |
| community.general | `13.4.0` | Galaxy artifact SHA-256 `efd1c0b5dc6f89b9667e4bd77f2426c30545861910dba188593871095ede1804` |

All remaining chart, provider, collection, application image, and CI image versions are
`VERIFY`. Before implementing their phase I will verify them against an official chart
index, release, registry, or `helm show chart/values`, replace `VERIFY` with an exact pin,
and record the evidence. An unverified dependency is not eligible for a completed phase.

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

Validation: `kyverno test`, policy application to all rendered resources, Trivy config
render, and exception-expiry checks.

Risks: breaking required infrastructure privileges, policy bypass through broad
exceptions, and enabling enforcement before existing resources comply.

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
- Cloudflare WARP private routing supersedes raw inbound WireGuard for administration;
  Cilium WireGuard still encrypts eligible cluster traffic.
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
