# ENVIRONMENT (fixed, do not change)

- 3 x86-64 PCs (pc-1, pc-2, pc-3), Ubuntu Server LTS, wired LAN, static IPs.
- Kubernetes: k3s, HA, embedded etcd, 3 server nodes, all schedulable.
- Control-plane VIP: kube-vip (ARP mode). LoadBalancer IPs: Cilium L2 announcements.
- k3s flags: --flannel-backend=none --disable-network-policy --disable=traefik
  --disable=servicelb --disable-kube-proxy; tls-san includes the VIP.
- CNI: Cilium (kube-proxy replacement, Hubble, Gateway API, WireGuard encryption).
- Provisioning: Ansible (nodes, k3s, kube-vip) and OpenTofu (Cloudflare, S3).
- GitOps: Argo CD (app-of-apps, ApplicationSets, sync waves). Argo Rollouts for canary.
- Access: Cloudflare Tunnel only, no inbound router ports. Admin access via WireGuard.
- Storage/backup: Longhorn (3 replicas), CloudNativePG, Velero, S3-compatible bucket.
- Secrets: SOPS + age for bootstrap only; OpenBao + External Secrets Operator at runtime.
- Observability: kube-prometheus-stack, Loki, Grafana Alloy, Tempo, Grafana, Alertmanager.
- Security: Kyverno, Trivy Operator, Pod Security Admission, Cosign verification.
- Identity: Keycloak or Authentik (choose one, write an ADR).
- CI: GitLab CI. Renovate. GitLab container registry.
- Optional last: 3 phones as arm64 workers (experimental, separate, documented).

# HARD RULES (violating any is a failure)

1. This repo is PUBLIC. Never commit secrets, tokens, private keys, unseal keys,
   kubeconfigs, tfstate, .env files, or my public IP. Secrets are SOPS-encrypted or in
   OpenBao. My domain and private RFC1918 addresses may appear ONLY in
   config/homelab.yaml (domain, node names and LAN IPs, VIP, LB pool, S3 endpoint and
   bucket, GitLab project path, timezone Africa/Casablanca); every other file reads from
   it. Use CHANGE_ME_* values until I supply real ones.
2. Pin every version (Helm charts, image tags or digests, Ansible collections, tofu
   providers, CI images). Never use `latest`.
3. Every workload needs requests/limits, liveness/readiness probes, a hardened
   securityContext (runAsNonRoot, drop ALL caps, seccomp RuntimeDefault,
   readOnlyRootFilesystem where possible), app.kubernetes.io/* labels, and a NetworkPolicy.
4. Everything declarative and idempotent. A second run changes nothing.
5. Never invent chart values, CRD fields, flags, versions, or APIs. Verify against
   upstream docs or `helm show values`. Record unverifiable items under "Unverified" in
   PROGRESS.md.
6. Never claim something works without running a validation command and recording the
   command and a real output summary. Never fabricate outputs or timings.
7. No TODO stubs or fake examples presented as finished. Implement fully, or list under
   "Not done" with the reason.
8. Do not edit earlier phases except to fix a defect; record why.
9. Conventional Commits, one logical change per commit, commit after each phase.
10. Never run destructive commands against real infrastructure. Write scripts and
    runbooks for the human to run.

# VALIDATION (offline only)

You cannot touch my hardware. Run what is possible: yamllint, markdownlint, shellcheck,
ansible-lint, `ansible-playbook --syntax-check`, `helm lint`, `helm template | kubeconform`,
kube-linter, `tofu fmt` and `tofu validate`, `kyverno test`, `promtool check rules`,
gitleaks, unit tests. A throwaway kind/k3d cluster may be used if available. Anything
needing real hardware goes into docs/VERIFY_ON_HARDWARE.md (by phase, with exact
commands and expected output) and is marked PENDING HARDWARE, never "passed".

# HUMAN-ONLY ITEMS (never block)

For anything only I can provide (domain, Cloudflare token, S3 bucket and keys, LAN
ranges, disk paths, GitLab tokens, OpenBao unseal keys), use variables and
SOPS-encrypted placeholder files, add exact instructions to HUMAN_TODO.md, and continue.

# DOCUMENTATION STANDARDS

- README.md (under ~150 lines): what this is and why I built it, hero architecture
  diagram (Mermaid), what it demonstrates (HA, GitOps, zero-inbound-port access,
  backup and DR, supply-chain security, observability, canary delivery), hardware table,
  live links, evidence links. Written for a recruiter or engineer with 5 minutes. First
  person, direct, technical, honest, no marketing language.
- docs/STATUS.md is the source of truth: Component | Implemented | Verified on hardware |
  Evidence link. Unproven items are "Planned" or "Untested". Only I may mark "Verified".
- ADRs in docs/adr/ in first person: context, decision, rejected alternatives, tradeoff.
- docs/journal/ (dated build log with template and seed entries), docs/incidents/
  (blameless postmortem template), docs/img/ (screenshot checklist: Argo CD tree,
  Grafana dashboards, Hubble map, status page, canary rollout, DR drill),
  docs/security/public-surface.md (exact public exposure: demo app, status page,
  optional read-only Grafana snapshot only), docs/skills-demonstrated.md (each
  component mapped to the DevSecOps skill it proves).
- DR and chaos result tables stay EMPTY for me to fill with real numbers.
- Do NOT create CONTRIBUTING.md, external-contributor templates, or "adopt this for
  your own cluster" language. Keep LICENSE (MIT), CODEOWNERS (me only), short SECURITY.md.
- Every component directory gets a short README (what, why, operate, test).

# REPO LAYOUT (do not deviate)

PLAN.md PROGRESS.md HUMAN_TODO.md README.md Makefile config/homelab.yaml
docs/{architecture.md,BUILD_SPEC.md,STATUS.md,VERIFY_ON_HARDWARE.md,adr/,runbooks/,dr/,journal/,incidents/,security/,img/}
infra/{ansible,tofu}  clusters/homelab/{bootstrap,projects,apps,root-app.yaml}
platform/  observability/  policies/  apps/  ci/  scripts/
.gitlab-ci.yml  renovate.json  .pre-commit-config.yaml  .sops.yaml  .yamllint
`make help` lists every target. One namespace per component (cert-manager,
longhorn-system, monitoring, apps-<name>); Cilium lives in kube-system.

# SELF-REVIEW (after every phase)

Act as a skeptical senior reviewer. Check: hard-rule violations (file and line),
PROGRESS claims without command output, invented config, plaintext secrets or leaked
values, unpinned versions, missing limits/probes/securityContext/NetworkPolicy,
idempotency, failure and reboot behavior. Fix everything found and record the result in
PROGRESS.md.

# SESSION RESUME

If a session starts with existing files, read AGENTS.md, PROGRESS.md, and the next
unfinished phase in docs/BUILD_SPEC.md, and continue from there. Never redo finished
phases.
