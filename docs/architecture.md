# Architecture

The target is a three-server k3s cluster with embedded-etcd quorum. kube-vip owns the
Kubernetes API virtual address. Cilium replaces kube-proxy, assigns LAN service
addresses, implements Gateway API, and encrypts eligible cross-node traffic.

```mermaid
flowchart LR
  GitLab[GitLab repository and CI] --> Argo[Argo CD]
  Admin[Administrator via WARP WireGuard] --> Tunnel[Cloudflare Tunnel]
  Internet[Public HTTPS] --> Tunnel
  Tunnel --> Gateway[Cilium Gateway API]
  Argo --> Platform[Platform desired state]
  Gateway --> Apps[Selected public applications]
  subgraph Cluster[Three-node k3s HA cluster]
    VIP[kube-vip API VIP]
    Etcd[Embedded etcd quorum]
    Cilium[Cilium and Hubble]
    Storage[Longhorn and CNPG]
    Platform
    Apps
  end
  VIP --> Etcd
  Cilium --> Gateway
  Platform --> Storage
```

Runtime proof remains linked from the [evidence map](evidence.md); diagrams describe
intended flow and are not proof that hardware is healthy.

## GitOps reconciliation flow

```mermaid
flowchart LR
  Git[GitLab main] --> Root[Root Application]
  Root --> Projects[Restricted AppProjects]
  Root --> Platform[Wave-ordered platform apps]
  Root --> Generator[Production ApplicationSet]
  Generator --> Apps[Application overlays]
  Renderer[Pinned yq, Kustomize, KSOPS CMP] --> Platform
  Renderer --> Apps
  Platform --> Cluster[Kubernetes API]
  Apps --> Cluster
  Drift[Out-of-band drift] --> Cluster
  Cluster -->|self-heal| Argo[Argo CD controllers]
  Argo --> Git
```

## Phase 4 edge traffic

```mermaid
flowchart LR
  Public[Public client] --> Edge[Cloudflare DNS and TLS]
  Edge --> Outbound[Outbound-only cloudflared replicas]
  Outbound --> PublicGateway[Cilium public Gateway]
  PublicGateway --> PublicRoute[Selected HTTPRoute]
  PublicRoute --> App[Public application]
  Admin[Enrolled WARP WireGuard client] --> PrivateRoute[Cloudflare private route]
  PrivateRoute --> InternalGateway[Cilium internal Gateway]
  Lan[Trusted LAN client with split DNS] --> InternalGateway
  InternalGateway --> AdminService[Internal administration service]
```

The public and administrative paths share no router port. OpenTofu owns the temporary
public Tunnel CNAME. Internal names resolve only through split DNS and the internal
Gateway's centrally configured load-balancer address.

## Phase 5 storage and recovery

```mermaid
flowchart LR
  Apps[Stateful workloads] --> PVC[Longhorn PVC]
  PVC --> R1[Replica on pc-1]
  PVC --> R2[Replica on pc-2]
  PVC --> R3[Replica on pc-3]
  PVC --> CSI[CSI snapshot]
  CSI --> Velero[Velero cluster backup]
  Postgres[CloudNativePG] --> WAL[WAL and base backup]
  R1 --> LonghornBackup[Longhorn backup]
  LonghornBackup --> S3[S3-compatible bucket]
  WAL --> S3
  Velero --> S3
```

Local replicas provide availability, not disaster recovery. Longhorn, CNPG, and Velero
use separate prefixes and scoped credentials in the same centrally configured bucket.

## Phase 6 secret flow

```mermaid
flowchart LR
  Age[Offline age identity] --> SOPS[SOPS bootstrap documents]
  SOPS --> Bootstrap[GitLab, Cloudflare, and S3 bootstrap Secrets]
  Operator[Human operator] -->|manual Shamir unseal| Bao[OpenBao HA Raft]
  Workload[Namespaced service account] -->|audience-bound token| Auth[Kubernetes auth]
  Auth -->|namespace read policy| Bao
  Bao --> ESO[External Secrets Operator]
  ESO --> Materialized[Namespaced Kubernetes Secret]
  Materialized --> App[Workload]
```

SOPS cannot depend on OpenBao because it establishes the services needed to start and
recover OpenBao. Runtime consumers receive short-lived identities and cannot write
secret data. Manual unseal remains an explicit availability tradeoff.

## Phase 7 telemetry flow

```mermaid
flowchart LR
  Nodes[Nodes and controllers] --> Prometheus[Prometheus]
  Probes[Blackbox probes] --> Prometheus
  Pods[Pod logs] --> Alloy[Grafana Alloy]
  Alloy --> Loki[Loki]
  Apps[Instrumented applications] --> OTel[OpenTelemetry Collector]
  OTel --> Tempo[Tempo]
  Prometheus --> Grafana[Grafana]
  Loki --> Grafana
  Tempo --> Grafana
  Prometheus --> Alertmanager[Alertmanager]
  OpenBao[OpenBao notification destinations] --> ESO[External Secrets]
  ESO --> Alertmanager
  ESO --> ArgoNotify[Argo CD notifications]
```

The telemetry backends are internal only. Their Longhorn volumes improve local
availability, but telemetry remains disposable relative to application and backup data.
Alertmanager and Argo CD receive distinct notification destinations from OpenBao.

## Phase 8 policy and supply-chain flow

```mermaid
flowchart LR
  Commit[Reviewed Git commit] --> CI[GitLab CI]
  CI --> Scan[Tests, SBOM, and Trivy gate]
  CI --> Sign[GitLab OIDC Cosign signature]
  Sign --> Registry[GitLab registry digest]
  Registry --> Argo[Digest promotion]
  Argo --> Kyverno[Kyverno admission]
  Kyverno --> Workload[Application Pod]
  Workload --> Trivy[Trivy Operator reports]
  Trivy --> Prometheus[Prometheus metrics]
  Prometheus --> Dashboard[Grafana security posture]
```

Phase 8 installs the admission and detection layers in Audit mode. Phase 9 supplies the
owned, keylessly signed images and digest-only promotion path. Deny promotion requires
clean reports and the explicit enforcement runbook.

## CI/CD and package flow

```mermaid
flowchart LR
  Commit[Reviewed commit] --> Tests[Lint, test, manifest gates]
  Tests --> Build[Buildx amd64 and arm64]
  Build --> SBOM[Syft SPDX]
  Build --> Trivy[Trivy gate]
  SBOM --> Sign[GitLab OIDC Cosign]
  Trivy --> Sign
  Sign --> Registry[GitLab registry digest]
  Registry --> Staging[Automatic staging digest commit]
  Registry --> Approval[Manual production approval]
  Approval --> Production[Production digest commit]
  Registry --> GHCR[GHCR API, worker, deployment packages]
```

## Backup and restore flow

```mermaid
flowchart LR
  Etcd[k3s embedded etcd] --> EtcdS3[Versioned S3 snapshots]
  CNPG[CloudNativePG] --> Base[Base backups]
  CNPG --> WAL[Continuous WAL]
  Longhorn[Longhorn volumes] --> LHBackup[Longhorn backups]
  CSI[CSI snapshots] --> Velero[Velero schedules]
  Base --> S3[S3-compatible object storage]
  WAL --> S3
  LHBackup --> S3
  Velero --> S3
  S3 --> Drills[Isolated restore objects]
  Drills --> Verify[Checksums, markers, row counts]
```
