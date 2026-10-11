# Progress Log

This file records only commands actually run and results actually observed. Runtime
checks against the three physical nodes are tracked separately as `PENDING HARDWARE`.

## Phase checklist

- [ ] Phase 0 — Skeleton and CI (repair required)
- [ ] Phase 1 — Nodes and k3s (repair required)
- [ ] Phase 2 — Cilium (repair required)
- [ ] Phase 3 — Argo CD (repair required)
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

Network access was available. Missing tools will be installed into the ignored local
tool directory by the pinned Phase 0 installer and re-inventoried before validation.

## Unverified

- All real-hardware behavior.
- Every dependency not yet listed with upstream evidence in `PLAN.md`.
- The GitLab pipeline, until run by GitLab.

## Not done

- No real node, cluster, Cloudflare account, S3 service, or Git remote was modified.
