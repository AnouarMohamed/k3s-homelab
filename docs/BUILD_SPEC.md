# PHASES

PHASE 0, Skeleton and CI: layout with READMEs; Makefile (help, lint, validate,
bootstrap, teardown); pre-commit (yamllint, gitleaks, markdownlint, ansible-lint,
kubeconform); .gitignore (age keys, .env, kubeconfig, .terraform, tfstate);
.sops.yaml with a placeholder recipient; config/homelab.yaml with CHANGE_ME values;
.gitlab-ci.yml stages lint/validate/security with pinned images, including a job that
fails on secrets and on files like *.age keys, kubeconfig, .env, *.tfstate;
renovate.json covering charts, images, collections, CI images, providers; README
skeleton with Mermaid diagram and phase status table; STATUS.md; ADRs: k3s over
kubeadm, Cilium over Flannel, Argo CD over Flux, Cloudflare Tunnel over port forwarding.

PHASE 1, Nodes and k3s: Ansible roles base, hardening (SSH key-only, no root, fail2ban,
ufw with justified port table, auditd baseline, CIS-alignment table of applied and
skipped controls), k3s (HA embedded etcd, flags above, scheduled etcd snapshots to S3),
kube_vip. Playbooks: site.yml, upgrade.yml (rolling, drain/uncordon), reset.yml. Token
via SOPS or ansible-vault. Makefile: bootstrap-nodes, upgrade-k3s, reset. Runbooks:
node-replacement, k3s-upgrade. Gate: ansible-lint clean, syntax-check passes.

PHASE 2, Cilium: Gateway API CRDs (pinned, installed BEFORE Cilium), Cilium values
(kubeProxyReplacement, k8sServiceHost=VIP, l2announcements, gatewayAPI, Hubble
relay+UI+metrics, operator replicas 2, WireGuard encryption, requests/limits), IP pool
and L2 policy, `make bootstrap-cni`, baseline NetworkPolicy Kustomize component
(default-deny, allow DNS, allow intra-namespace; no cluster-wide deny breaking
kube-system), troubleshooting runbook, ADR for WireGuard. Gate: helm template passes
kubeconform; connectivity test goes to VERIFY_ON_HARDWARE.md.

PHASE 3, Argo CD: pinned install, SOPS-based repo credentials (ksops or helm-secrets,
ADR), root app-of-apps, AppProjects with restricted sources and destinations, one
Application per platform component (Cilium adopted with identical values, Argo CD
self-managed), ApplicationSet for apps/, documented sync waves (CRDs, CNI, cert-manager,
storage, secrets, observability, apps), RBAC with admin and read-only roles, local
break-glass account, targetRevision main only, UI internal only, `make bootstrap-gitops`,
recovery runbook.

PHASE 4, Certs, DNS, public access: tofu for Cloudflare tunnel, DNS, scoped tokens
(ADR on state handling); cert-manager with staging and prod ClusterIssuers (DNS-01) and
a wildcard cert; external-dns (domain filter, TXT ownership); cloudflared (2 replicas,
anti-affinity); two Gateways (internal on LAN LB IP, public behind tunnel) with
HTTPRoutes and TLS; a public whoami test app; split-horizon DNS doc; traffic-flow
diagram. Domain comes from config/homelab.yaml only.

PHASE 5, Storage and backups: Longhorn (default StorageClass, 3 replicas, S3 backup
target, recurring snapshot/backup jobs), CloudNativePG (3-instance cluster, WAL
archiving and base backups to S3, ScheduledBackup), Velero (CSI snapshots, daily and
hourly schedules, TTLs), tofu for the bucket, PVC-survives-reschedule test Job and
script, docs/dr/restore-drill-storage.md with an empty results template. local-path
stays non-default.

PHASE 6, Secrets: OpenBao HA (Raft on Longhorn, TLS via cert-manager, audit log PVC),
init/unseal runbook (honest that auto-unseal is out of scope), Kubernetes auth with
per-namespace policies, config as code, External Secrets Operator with a
ClusterSecretStore, migrate runtime secrets from SOPS where feasible (ADR listing what
must stay in SOPS and why), rotation and break-glass runbooks. No secret values in Git.

PHASE 7, Observability: kube-prometheus-stack (justified retention and storage),
ServiceMonitors for every installed component, Loki + Alloy with retention, Tempo +
OTel Collector, Grafana datasources and dashboards as code (cluster, node,
Cilium/Hubble, Argo CD, Longhorn, Postgres, etcd), alert rules with runbook_url (node
down, etcd leader changes, disk pressure, cert expiry, Argo out-of-sync, backup failure,
Longhorn degraded, restarts, API latency), watchdog alert, blackbox probes, Alertmanager
routing with the channel secret from OpenBao, Argo CD notifications, SLOs (Sloth or
Pyrra). Gate: promtool check rules in CI.

PHASE 8, Policy and supply chain: Kyverno policies (requests/limits, probes, no latest,
non-root, read-only FS, drop caps, seccomp, no privileged/hostPath, labels, require
NetworkPolicy, registry allowlist, Cosign verification), Audit-first then Enforce
rollout plan with an exceptions table, PSA labels via Kustomize, `kyverno test` cases in
CI, Trivy Operator with metrics and dashboard, Kubescape/kube-bench notes,
docs/security/threat-model.md (short STRIDE) and a posture summary. Fix earlier phases
that would violate enforced policies.

PHASE 9, Demo app and delivery: the app chosen in PLAN.md, small and genuine, with
multiple services where sensible, Postgres via CNPG and Redis if needed, health
endpoints, Prometheus metrics, OTel traces, unit tests. Multi-stage non-root multi-arch
Dockerfiles. CI: lint, test, build (buildx amd64+arm64), SBOM (Syft), Trivy gate,
keyless Cosign signing via GitLab OIDC, push to registry, image tag update through Git
(ADR), manifest validation, tofu plan. Kustomize base + staging/prod overlays, Argo
Rollouts canary with Prometheus AnalysisTemplate, HPA, PDBs, topology spread,
NetworkPolicies, ExternalSecrets, ServiceMonitor, HTTPRoute, dashboard and SLO,
release/rollback runbook. Must pass Kyverno enforce mode. Production requires a manual
approval gate.

PHASE 10, Identity and self-hosted apps: Keycloak or Authentik with CNPG, config as
code, OIDC SSO for Argo CD and Grafana (oauth2-proxy where needed), group-based RBAC,
MFA for admins. Apps: Vaultwarden, Homepage, Uptime Kuma (others only after a documented
capacity check), all meeting every workload rule, covered by Velero and monitoring.
Public status page for selected services only. SSO-recovery runbook with local
break-glass accounts. List optional extra apps (Paperless-ngx, Immich, Jellyfin,
Nextcloud, AdGuard Home, Gitea) in HUMAN_TODO.md for me to choose.

PHASE 11, Chaos and DR: Chaos Mesh (restricted to a test namespace) with experiments as
code (pod kill, network delay/partition, CPU stress, IO latency), k6 load scripts, and
seven DR drill documents in docs/dr/ (node power-off under traffic, quorum loss and
recovery, etcd snapshot restore from S3, Postgres failover and PITR, Velero namespace
restore, single-node rebuild, full bare-metal rebuild), each with pre-checks, rollback,
expected result, and an EMPTY results table (time to detect, time to recover, data
loss, lessons). Mark results PENDING HARDWARE.

PHASE 12, Polish: final README per the documentation standards, final architecture
diagrams in Mermaid (network, storage, secrets, GitOps, CI/CD, backup), ADR index
review, runbook index with every alert linked, SECURITY.md, LICENSE, CODEOWNERS,
full-history gitleaks, dead-file cleanup, `make help` complete, compatibility matrix and
upgrade guide, optional experimental phone-worker doc, badges. Every README claim must
link to a file, drill result, screenshot placeholder, or live URL; unproven items
labelled Planned or Untested.

# FINAL DELIVERABLES

When all phases are done, output: (1) a table of phases with status (Done / Pending
hardware / Unverified items), (2) the complete HUMAN_TODO.md, (3) the ordered list of
commands I run to bring everything up on real hardware, (4) the top 10 risks and what
to check first when something fails.
