# Progress Log

This file records only commands actually run and results actually observed. Runtime
checks against the three physical nodes are tracked separately as `PENDING HARDWARE`.

## Phase checklist

- [x] Phase 0 — Skeleton and CI (offline validation complete)
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

## Unverified

- All real-hardware behavior.
- Every dependency not yet listed with upstream evidence in `PLAN.md`.
- The GitLab pipeline, until run by GitLab.

## Not done

- No real node, cluster, Cloudflare account, S3 service, or Git remote was modified.
