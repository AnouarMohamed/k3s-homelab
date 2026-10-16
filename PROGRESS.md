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
| 2026-10-14 | rejected AWS node resize | A reviewed OpenTofu plan contained `0 to add, 3 to change, 0 to destroy` for an in-place resize from `m7i-flex.large` to `m7i-flex.xlarge`. AWS rejected all three modifications with `FreeTierRestrictionError`; no type changed. The stopped instances were restarted, all three nodes returned Ready, and the unsupported repository change was discarded. |
| 2026-10-14 | temporary AWS evidence profile | The allowed 2-vCPU nodes reached 98–99% scheduled CPU requests. Automated Application reconciliation was paused and duplicate control-plane, monitoring, policy, and demo replicas were reduced in live state only. Etcd, all Cilium agents, and all Longhorn managers remained at three replicas; canonical Git manifests remain HA. |
| 2026-10-14 | Velero rollout at commit `4be3162` | Argo synchronized the repaired `v1.18.2` digest and the image pulled successfully. Velero then timed out reaching the API because its egress policy allowed service port 443 but not Cilium's translated backend port 6443. Adding TCP/6443 made the Deployment Ready; the policy and validator were repaired from that observation. |
| 2026-10-14 | GitLab pipeline `2948227688` | Both Sentinel multi-architecture images compiled and were pushed to GitLab Container Registry. The build job then failed because its Buildx template emitted no valid digest, so downstream security, signing, promotion, and GHCR jobs were skipped. Digest extraction now parses Buildx's stable `Digest:` output, matching the repository's existing image verifier. |
| 2026-10-14 | `make aws-validation-apply` for storage expansion | The reviewed plan reported `0 to add, 3 to change, 0 to destroy` and expanded only the three encrypted gp3 root volumes from 100 GiB to 200 GiB. SSM `growpart` and `resize2fs` completed on all nodes; each root filesystem then reported 206,900,281,344 bytes and Longhorn detected about 192 GiB usable with 170–176 GiB available. |
| 2026-10-15 | live Grafana startup logs | Grafana 13.2.3 downloaded its suggested plugins without explicit versions. The chart configuration now disables suggested-plugin preinstallation and automatic plugin updates; repository validation asserts both rendered settings. |
| 2026-10-15 | GitLab pipeline `2950068242` | Image builds, Trivy gates, application tests, repository validation, and the deployment package passed. The SBOM job failed before its script because the pinned minimal Syft image contains no shell for GitLab Runner; the equally versioned and digest-pinned upstream debug variant supplies the required shell. |
| 2026-10-15 | live observability pod logs | Monitoring API clients timed out against the API backend port, Alloy could not create `/tmp/alloy` on its read-only root, and OTel tried to resolve the literal host `${env:MY_POD_IP}`. The network policy, Alloy ephemeral storage, and OTel environment references were repaired from those observed failures. |
| 2026-10-15 | Longhorn recovery after storage expansion | pc-3's instance manager was initially unschedulable at 94% requested CPU. Reapplying the live-only evidence profile freed capacity; the manager became Running and every attached Longhorn volume changed from degraded or unknown to healthy while retaining three configured replicas. |
| 2026-10-15 | GitLab pipeline `2950298571` | The debug Syft image supplied the shell GitLab Runner requires, then the job proved its binary is installed at `/syft` rather than on BusyBox's PATH. The SBOM commands now use that explicit upstream path. |
| 2026-10-15 | live Grafana restart | The dashboard sidecar reached the API and completed its initial sync after the TCP/6443 repair. The replacement pod then exposed a rollout deadlock: the default surge pod could not attach Grafana's single-writer Longhorn volume while the old pod remained. Grafana now uses the chart's verified `Recreate` strategy. |
| 2026-10-15 | live Grafana sidecar probes | The sidecar logged that its health server listens on 8080 and successfully synchronized dashboards, but Kubernetes repeatedly restarted it because both probes targeted 8084. The probes now target the observed health port and rendering validation locks it in. |
| 2026-10-15 | Grafana rollout after probe and strategy repairs | The Recreate rollout released and reattached the healthy Longhorn volume, the sidecar completed dashboard synchronization, and the replacement Grafana pod reached `2/2 Running` with zero restarts. |
| 2026-10-15 | live Grafana datasource API | The overview loaded with 27 panels but Grafana reported zero datasources because `additionalDataSources` requires the disabled datasource sidecar. Native file provisioning now renders Prometheus, Loki, and Tempo definitions directly into Grafana's provisioning ConfigMap. |
| 2026-10-15 | live datasource health and Prometheus query | Prometheus and Loki returned healthy datasource checks. Tempo initially timed out because its chart exposes the query API on TCP/3200 rather than TCP/3100; after correcting the URL all three checks passed, and Prometheus returned 3 Ready nodes. |
| 2026-10-15 | GitLab pipeline `2950648563` | Every lint, validation, test, image build, package, SBOM, Trivy, and gitleaks job passed. Signing alone failed before its script because the minimal Cosign image has no shell. The replacement job downloads the pinned `v3.0.5` Linux binary in a shell-capable pinned image; its release SHA-256 and reported version were verified locally. |
| 2026-10-15 | GitLab pipeline `2951442910` | The checksum-verified Cosign 3.0.5 binary signed the Sentinel API image successfully. Its SPDX JSON attestation then failed because the job declared the JSON document as the `spdx` predicate type; Cosign's installed help identifies `spdxjson` as the matching type. |
| 2026-10-15 | live CNPG recovery | The operator timed out first against the Barman plugin on TCP/9090, then database bootstrap jobs timed out against the reserved Kubernetes API identity. The repaired policies allowed both paths; the storage verification cluster reached 3/3 Ready before its live-only evidence profile was reduced, and Sentinel staging reached a healthy primary. |
| 2026-10-15 | live Sentinel staging rollout | The lowercase GitLab registry path and current pipeline digests pulled successfully. Argo Rollouts reported the API `Healthy`; one API pod, one probe worker, and the database primary were Ready, and Prometheus scraped all three targets. |
| 2026-10-15 | live Keycloak startup | The pinned stock image failed Quarkus augmentation on a read-only root filesystem at `/opt/keycloak/lib/quarkus/transformed-bytecode.jar`. With the exact documented writable-root exception, Keycloak completed augmentation, initialized its database, and became Ready. |
| 2026-10-15 | live Prometheus queries | All three node-exporter targets and all three nodes reported up/Ready, the shortest positive certificate lifetime was about 89 days, and no critical alerts remained after the stale backup-job rule was bounded to failures created within the last hour. |
| 2026-10-15 | GitHub Actions run `38795313954` | All six matrix jobs published and keylessly signed the Homepage, Keycloak, Sentinel, Uptime Kuma, Vaultwarden, and whoami deployment packages. Anonymous Registry API requests returned HTTP 200 for every package's `main` manifest. |
| 2026-10-15 | GitLab pipeline `2952579612` | Repository validation, unit and integration tests, multi-architecture builds, deployment packaging, SBOM generation, Trivy, gitleaks, GitLab Cosign signing and SPDX JSON attestations all passed. After the missing CI credentials were installed, staging and manually approved production digest promotions passed; the GHCR mirror and all three GHCR signing operations also passed. |
| 2026-10-15 | `scripts/validate-observability.sh` | The refined restart panel passed deterministic rendering, seven Helm lints, kubeconform, ten promtool-checked rules, PromQL parsing, and eight KubeLinter checks. |
| 2026-10-16 | Cosign `v3.0.5` verification | Independent verification of the GHCR Sentinel API, worker, and deployment-package artifacts at commit `389d17a` validated each GitLab OIDC identity claim, signing certificate, and offline Rekor transparency-log entry. |
| 2026-10-16 | GitLab pipeline `2954412602` | Lint, full repository validation, unit and integration tests, multi-architecture builds, deployment packaging, SBOM, Trivy, gitleaks, and GitLab signing passed. Staging promotion exposed an expired personal promotion token, and the GHCR mirror exposed a transient worker-index finalization failure; both are recorded as defects rather than a successful pipeline. |
| 2026-10-16 | GitLab pipeline `2954641982` | A temporary locked project runner completed the pipeline after the free-namespace compute quota blocked shared runners. Lint, repository validation, tests, multi-architecture builds with pinned BuildKit, deployment packaging, SBOM, Trivy, full-history gitleaks, GitLab signing, job-token staging and production promotions, GHCR mirroring, and GHCR signing passed. The temporary runner, GitLab runner record, and credential volume were removed afterward. |

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
- Velero's default-deny egress policy now permits the Kubernetes API backend port used
  by Cilium kube-proxy replacement. Storage validation asserts the TCP/6443 rule so the
  startup failure cannot silently return.
- Argo CD now propagates child `Application` health so app-of-apps sync waves wait for
  dependencies instead of merely creating every child at once. Restricted projects now
  include only the additional destinations and resource kinds rendered by their pinned
  Cilium, CloudNativePG, and Prometheus charts.
- Registry inspection replaced two image digests that did not exist upstream. The
  Longhorn recurring-job selector is now the JSON string required by the chart rather
  than a YAML list that Helm stringified as a Go map.
- Grafana's default suggested-plugin installation introduced dependencies outside the
  repository's pinning controls. Suggested preinstallation and automatic plugin updates
  are now disabled in the rendered configuration and guarded by validation.
- GitLab Runner could not start the shell-based SBOM job with Syft's minimal image.
  The job now uses the upstream `v1.54.0-debug` image at its verified multi-platform
  digest; the Syft application version remains unchanged.
- The monitoring namespace now permits the Cilium-translated Kubernetes API backend
  port. Alloy receives an ephemeral writable mount at its documented storage path, and
  OTel's pod-IP environment references remain expandable in the rendered collector
  configuration.
- The SBOM job invokes `/syft` explicitly because the upstream debug image keeps the
  scanner outside BusyBox's default PATH.
- Grafana uses `Recreate` deployment semantics so its one-replica Deployment releases
  the single-writer Longhorn volume before starting a replacement pod.
- Grafana's dashboard sidecar readiness and liveness probes use its observed health
  server port 8080.
- Grafana now provisions all three datasources without relying on a disabled sidecar,
  and Tempo uses the query API port rendered by its pinned chart.
- GitLab signing jobs install the checksum-verified Cosign release binary in a pinned,
  shell-capable image because GitLab Runner cannot execute scripts in Cosign's minimal
  release container.
- CNPG's operator can reach the Barman plugin and instance-manager port, while database
  pods use Cilium's `kube-apiserver` entity for bootstrap API access under default deny.
- Argo Rollouts uses the same explicit Kubernetes API entity instead of relying on
  ambiguous service translation through a standard IP block.
- GitLab registry repository names are rendered in lowercase without changing the
  case-preserving GitLab repository URL or project path.
- The policy validator now derives its expected Sentinel registry glob from that same
  lowercase path; its earlier mixed-case expectation failed the GitLab repository gate
  even though the rendered policy was correct.
- Keycloak's stock image has an exact writable-root exception because its `start`
  command performs Quarkus augmentation; non-root execution, dropped capabilities,
  RuntimeDefault seccomp, pinned image, and network isolation remain enforced.
- Backup job alerts consider only failures created within the last hour, preventing a
  retained failed Job from masking later successful recurring snapshots indefinitely.
- The restart-concentration panel now reports a rolling fifteen-minute increase and
  uses the latest/maximum values instead of summing overlapping range samples, which
  previously exaggerated historical crash-loop counts.
- Sentinel promotion uses GitLab's short-lived, same-project `CI_JOB_TOKEN` push
  permission instead of a stored personal token. GHCR recursive copies retry four
  times with bounded delays before failing a genuine registry error.
- Sentinel's Buildx builder now uses a release-and-digest-pinned BuildKit image and a
  bounded bootstrap retry. A cold temporary runner exposed the former implicit
  `buildx-stable-1` pull when Docker Hub reset that unpinned download.

## Not done

- The 44 Argo CD Applications exist in AWS, but the capacity-bounded evidence profile
  and placeholder runtime credentials mean the full tree is not yet Healthy.
- The operations dashboard has been opened against live telemetry. Its first draft
  capture exposed missing Sentinel metrics; the repaired capture now has live Sentinel
  metrics but still shows the intentionally paused Argo CD applications and unreachable
  public whoami target, so it is not accepted as final portfolio evidence.
- No final screenshot has been committed.
- kube-vip ARP and Cilium L2 announcement behavior cannot be proven in AWS and remain
  pending broadcast-capable hardware.
- The seven-day telemetry storage-growth observation has not started.
