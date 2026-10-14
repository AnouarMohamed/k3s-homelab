# Progress

Observed results only are recorded here. Expected AWS and cluster behavior remains in
the runbooks and verification checklist until it is observed.

## Current work

Temporary AWS validation is active in `eu-west-1`. Three pinned
`m7i-flex.large` instances, an internal API load balancer, and the versioned backup
bucket are deployed with no security-group ingress from the Internet. The canonical
repository architecture remains the three-PC k3s cluster; AWS is a short-lived
substitute for tests that do not depend on LAN ARP or L2 broadcast behavior.

## Observed repository validation

| Date | Command | Real output summary |
| --- | --- | --- |
| 2026-10-14 | `make ansible-templates` | Passed 5 tasks; both k3s and kube-vip templates parsed and all assertions passed. |
| 2026-10-14 | `make ansible-syntax` | Parsed `site.yaml`, `upgrade.yaml`, and `reset.yaml` without syntax errors. |
| 2026-10-14 | `make validate-observability` | Helm lint passed for 7 charts; kubeconform and kube-linter reported no invalid resources; promtool accepted 10 alert rules and all dashboard PromQL; deterministic rendering matched. |
| 2026-10-14 | `make validate-aws-validation` | OpenTofu reused pinned AWS provider 6.68.0 and reported the configuration valid. No account was accessed. |
| 2026-10-14 | `make aws-validation-tools` | Checksum verification passed and Session Manager plugin 1.2.814.0 was installed under `.tools/bin`. |
| 2026-10-14 | `make lint` | Markdown and Ansible lint passed; tracked SOPS documents produced configured yamllint warnings only. |
| 2026-10-14 | `make validate` | All repository validators completed successfully, including deterministic chart rendering, kubeconform, kube-linter, Kyverno's 10 policy tests, promtool, Sentinel unit tests, GHCR package policy, and OpenTofu validation. |
| 2026-10-14 | `make security` | After excluding only the explicitly ignored `.runtime/` credential directory from the directory scan, Gitleaks found no leaks in repository content or across all 52 commits. Forbidden-file validation separately confirms runtime credentials are not tracked. |
| 2026-10-14 | `make aws-validation-apply` | OpenTofu created the internal load balancer, private network controls, versioned S3 bucket, IAM role, and three validation nodes after the reviewed plan. The first `t3.large` attempt was rejected by the account's Free-plan instance restrictions before any instance was created; the plan was repaired to the eligible pinned `m7i-flex.large` type and applied successfully. |
| 2026-10-14 | `make aws-validation-bootstrap-nodes` | All three nodes completed preparation and hardening; k3s `v1.36.5+k3s1` formed a three-server embedded-etcd control plane through the internal load balancer. The API `/readyz?verbose` reported `etcd`, `etcd-readiness`, and every other readiness check passing. |
| 2026-10-14 | second `make aws-validation-bootstrap-nodes` | Idempotence run completed with `changed=0`, `unreachable=0`, and `failed=0` for all three hosts. |
| 2026-10-14 | `make aws-validation-bootstrap-cni` | Gateway API `v1.6.1` CRDs were established and Cilium `1.20.2` deployed after correcting the observed AWS interface name. All three Cilium agents, both operators, three Envoy pods, two Hubble relays, Hubble UI, CoreDNS, and metrics-server became Ready. |
| 2026-10-14 | `kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose` | Cilium reported Kubernetes OK, kube-proxy replacement enabled, 3/3 nodes reachable, Hubble OK, 41/41 controllers healthy, and 97 modules OK with none degraded or stopped. |
| 2026-10-14 | `kubectl -n kube-system exec ds/cilium -- cilium-dbg encrypt status` | WireGuard was enabled on `cilium_wg0`; the inspected node reported two peers. |
| 2026-10-14 | `k3s etcd-snapshot save --name validation-pre-platform` | The first live S3 snapshot attempt failed before upload: the IAM role's prefix-conditioned `ListBucket` permission denied K3s's bucket-existence check. This failure led to the scoped policy repair recorded below. |
| 2026-10-14 | repeat `k3s etcd-snapshot save --name validation-pre-platform` | After an OpenTofu plan of `0 to add, 1 to change, 0 to destroy` updated only the inline IAM policy, K3s saved the snapshot successfully. `aws s3api head-object` confirmed a 13,656,096-byte object under `k3s-etcd/` with `AES256` server-side encryption. |
| 2026-10-14 | `make validate` | The full repository suite passed after the live-bootstrap repairs, including Ansible syntax/template assertions, deterministic Helm/Kustomize rendering, kubeconform, kube-linter, 10 Kyverno tests, promtool, Go tests, GHCR package policy, and both OpenTofu modules. |
| 2026-10-14 | `make lint` | Ansible lint passed its production profile, markdownlint reported zero issues across 128 Markdown files, and SOPS ciphertext produced only the configured yamllint warnings. |
| 2026-10-14 | `make bootstrap-gitops` | Argo CD chart `10.10.2` installed successfully; its server and renderer-enabled repository server rolled out, restricted projects were applied, and the root Application was created from GitLab `main`. |
| 2026-10-14 | first root Application sync | The root expanded to 44 Applications, but dependent Applications synchronized concurrently before their CRDs existed. Argo also rejected Cilium, CloudNativePG, and Prometheus resources omitted from their restricted project allowlists. These are observed failures, not successful deployment evidence. |
| 2026-10-14 | live image and volume inspection | Snapshot Controller and the Velero AWS plugin reported `NotFound` for their configured image digests. Longhorn rejected the rendered recurring-job selector as invalid JSON, leaving four PVCs Pending. Registry inspection and the pinned Longhorn values schema were used for the repairs. |
| 2026-10-14 | GitLab pipeline `2947394669` | All lint, repository validation, unit, integration, and deployment-package jobs passed. The multi-architecture image build completed compilation but failed while pushing because GitLab's registry token endpoint returned HTTP 500; the failed job was retried once. |
| 2026-10-14 | Argo reconciliation after commit `3ab2bd3` | The corrected Longhorn StorageClass was recreated and began binding the previously blocked volumes. Snapshot Controller's corrected image pulled. Cilium's canonical `enp3s0` and ARP-VIP settings could not run on AWS; self-heal was paused for the root and Cilium Applications and live-only overrides selected the observed `enp39s0` interface and each server's local API. All three agents then became Ready. |
| 2026-10-14 | Docker Registry API plus `make validate-storage` | The registry returned `sha256:37396519f399536e5f01427d723565ae69294ec3fb5625cf1c87c09eaa9de16b` for the Velero `v1.18.2` multi-platform manifest. Storage validation then passed deterministic rendering, four Helm lints, kubeconform, and kube-linter with the repaired digest. |
| 2026-10-14 | full Argo reconciliation | Argo CD's application controller was repeatedly OOM-killed at its 1 GiB limit while reconciling 44 Applications and rapidly changing Longhorn resources. Node memory use remained between 51% and 59%; the controller request and limit were increased to 768 MiB and 2 GiB respectively before reconciliation resumed. |

## Defects repaired during this work

- The former cluster dashboard exposed only two inventory totals. It is now an
  operator-first overview with live user impact, delivery, resource pressure, network,
  database, backup, and control-plane signals.
- Longhorn 1.12 robustness uses the `state` label. The earlier numeric comparison could
  miss degraded volumes; the alert and dashboards now query `degraded` and `faulted`
  label states.
- Dashboard validation previously assumed each JSON value occupied one YAML line. It
  now accepts readable multiline JSON and syntax-checks every PromQL expression.
- The k3s playbook now waits for the shared API endpoint from the initial server, which
  works for both a LAN VIP and an internal validation load balancer.
- The pinned K3s source uses a credential chain that includes the EC2 IAM provider.
  The AWS inventory can therefore omit persistent S3 access keys while retaining a
  narrowly scoped instance role; the S3 region and 28-snapshot remote retention are
  now explicit.
- The Cilium bootstrap can omit LB IPAM and L2 announcements only for AWS validation,
  where VPC networking cannot reproduce LAN broadcast behavior. Canonical installs
  still enable and validate both resources.
- Systems Manager SSH now quotes its proxy command correctly, Ubuntu creates the
  volatile OpenSSH runtime directory before validation, and k3s registers the
  canonical node names explicitly.
- The pinned AWS instance family exposes `enp39s0`, not the assumed `ens5`; both the
  inventory and Cilium bootstrap now use the interface observed on all three nodes.
- Recovery after removal of a stale pre-canonical node registration now has an
  explicit, marker-backed initial-server rejoin path. The recovered node rejoined the
  surviving etcd quorum successfully.
- `make bootstrap-platform` referenced a missing file. It now has an executable,
  bounded waiter that fails on Argo CD sync errors and succeeds only when discovered
  applications are both Synced and Healthy; portfolio validation checks the bootstrap
  scripts exist.
- The live etcd snapshot test showed that K3s checks bucket existence without an S3
  prefix before writing its prefix-scoped object. The AWS node policy now permits
  listing only the dedicated validation bucket while retaining object permissions
  under `k3s-etcd/*`.
- Velero's pinned application digest referenced no registry manifest. The pin now uses
  the digest returned by Docker's registry for the published `v1.18.2` multi-platform
  tag; the AWS plugin remains separately pinned to its verified manifest digest.
- Argo CD's application controller exhausted its original 1 GiB limit during the first
  full reconciliation. Its bounded memory request and limit now accommodate the
  observed 44-Application workload without removing the resource ceiling.
- Argo CD now propagates child `Application` health so app-of-apps sync waves wait for
  dependencies instead of merely creating every child at once. Restricted projects now
  include only the additional destinations and resource kinds rendered by their pinned
  Cilium, CloudNativePG, and Prometheus charts.
- Registry inspection replaced two image digests that did not exist upstream. The
  Longhorn recurring-job selector is now the JSON string required by the chart rather
  than a YAML list that Helm stringified as a Go map.

## Not done

- Argo CD and the remaining platform applications have not been bootstrapped in AWS.
- No dashboard has been opened against live telemetry.
- No screenshot has been captured.
- kube-vip ARP and Cilium L2 announcement behavior cannot be proven in AWS and remain
  pending broadcast-capable hardware.
- The seven-day telemetry storage-growth observation has not started.
