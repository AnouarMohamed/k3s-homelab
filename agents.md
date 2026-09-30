# Homelab Platform: Agent Operating Manual

You are building a production-grade, GitOps-managed Kubernetes homelab as a
public portfolio repository. Quality bar: a senior platform engineer should be
able to clone this repo, read the docs, and rebuild the entire environment from
wiped disks with minimal manual steps.

## Environment
- 3 x86-64 PCs (pc-1, pc-2, pc-3), Ubuntu Server LTS, wired LAN, static IPs.
- Kubernetes: k3s, HA, embedded etcd, 3 server nodes (all schedulable).
- Control-plane VIP: kube-vip. Service LoadBalancer IPs: Cilium L2 announcements.
- CNI: Cilium (kube-proxy replacement, Hubble, Gateway API). k3s is installed
  with flannel and the default network policy controller DISABLED.
- GitOps: Argo CD, app-of-apps pattern. Git is the single source of truth.
- Public access: Cloudflare Tunnel only. No inbound ports open on the router.
- Admin access: WireGuard. The kube-api and Argo CD UI are never public.
- Secrets: SOPS + age for bootstrap; OpenBao + External Secrets Operator after.
- Repo host: GitLab. CI: GitLab CI.

## Hard rules
1. NEVER commit plaintext secrets, tokens, private keys, or real IPs/domains
   that should be variables. Use placeholders and SOPS-encrypted files.
2. Pin every version: Helm chart versions, container image tags (digest where
   practical), Ansible collection versions, Terraform/OpenTofu providers.
   Never use `latest`.
3. Every Kubernetes workload MUST have: resource requests and limits,
   liveness/readiness probes, securityContext (runAsNonRoot, readOnlyRootFilesystem
   where possible, drop ALL capabilities, seccompProfile RuntimeDefault),
   and a NetworkPolicy.
4. Everything is declarative and idempotent. Running any playbook or apply
   twice must produce no changes the second time.
5. Do not invent APIs, chart values, or CRD fields. If unsure, read the
   upstream chart's values.yaml or documentation, and state what you checked.
   If you cannot verify something, write it in PROGRESS.md under "Unverified".
6. Do not claim something works unless you ran a validation command and saw the
   output. Paste the command and its result summary in PROGRESS.md.
7. Make minimal, focused changes per phase. Do not refactor earlier phases
   unless a defect requires it, and record why.
8. No placeholder code, TODO stubs, or "example only" configs presented as
   finished. Either implement it fully or list it under "Not done".

## Repo layout (do not deviate)

.
├── AGENTS.md
├── PROGRESS.md
├── README.md
├── Makefile # single entry point: make help lists all targets
├── docs/
│ ├── architecture.md # diagrams (Mermaid) + explanation
│ ├── adr/ # one file per decision: 0001-title.md
│ ├── runbooks/ # operational procedures
│ └── dr/ # disaster recovery drills and results
├── infra/
│ ├── ansible/ # inventory, roles, playbooks
│ └── tofu/ # cloudflare, s3 backup bucket
├── clusters/homelab/ # Argo CD bootstrap + app-of-apps root
├── platform/ # cilium, cert-manager, longhorn, openbao, etc.
├── observability/ # prometheus stack, loki, tempo, dashboards, alerts
├── policies/ # kyverno policies + tests
├── apps/ # demo app + self-hosted apps (kustomize base/overlays)
├── ci/ # reusable CI templates and scripts
└── .gitlab-ci.yml


## Conventions
- Namespaces: one per component (e.g. `cilium`? no: use kube-system for Cilium;
  otherwise `cert-manager`, `longhorn-system`, `monitoring`, `apps-<name>`).
- Labels on everything: app.kubernetes.io/name, /instance, /part-of, /managed-by.
- Helm via Argo CD Application with pinned chart version and values in Git.
- Kustomize for our own manifests. YAML must pass yamllint and kubeconform.
- Commit messages: Conventional Commits. One logical change per commit.
- Docs: every component gets a short README (what, why, how to operate, how to
  test) in its directory.

## Definition of done for EVERY phase
- All files created and committed-ready (no uncommitted scratch files).
- Validation commands listed in the phase were run and passed.
- PROGRESS.md updated: what was done, commands run, results, unverified items,
  known limitations.
- docs/ updated where the phase changes architecture or operations.
- An ADR added for any non-obvious decision.

## Working method
At the start of each phase: read AGENTS.md and PROGRESS.md, restate the phase
goal in 3 lines, list the files you will create, then implement. At the end:
run the validations, fix failures, then update PROGRESS.md. If blocked, stop and
state exactly what you need from the human. Do not guess.

One correction: in the Conventions section, the Cilium namespace line is messy as written. Change it to: Namespaces: one per component (cert-manager, longhorn-system, monitoring, apps-<name>); Cilium lives in kube-system.