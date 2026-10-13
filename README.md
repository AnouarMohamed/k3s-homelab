# Three-node k3s homelab

This repository describes the k3s cluster I run on three x86-64 PCs. All three nodes
run the control plane, embedded etcd, and workloads. Git holds the node setup, cluster
resources, policy, and application delivery. Cloudflare Tunnel and WARP provide access,
so I do not open inbound ports on the router.

```mermaid
flowchart LR
  Git[GitLab] --> CI[CI]
  CI --> Images[Container registry]
  CI --> Argo[Argo CD]
  Users[Public users] --> Tunnel[Cloudflare Tunnel]
  Admin[Private admin access] --> WARP[Cloudflare WARP]
  Tunnel --> Gateway[Cilium Gateway]
  WARP --> Gateway
  Argo --> Cluster
  Images --> Cluster
  subgraph Cluster[Three k3s servers]
    API[kube-vip API address]
    Network[Cilium network]
    Data[Longhorn and PostgreSQL]
    Signals[Metrics logs and traces]
    Apps[Applications]
  end
  Gateway --> Apps
  Apps --> Data; Cluster --> Signals
```

## What runs on it

- Cilium, Hubble, Argo CD, and Argo Rollouts
- Longhorn, CloudNativePG, and Velero
- OpenBao and External Secrets
- Prometheus, Grafana, Loki, Alloy, Tempo, and OpenTelemetry
- Kyverno and Trivy Operator
- Homelab Sentinel, Keycloak, and Vaultwarden
- Homepage and Uptime Kuma
- Chaos Mesh

## Layout

```text
apps/           application source and Kubernetes resources
clusters/       Argo CD entry points for the homelab cluster
config/         values that belong to this installation
infra/          Ansible node setup and OpenTofu cloud resources
observability/  metrics, logs, traces, dashboards, and alerts
platform/       shared cluster services
policies/       admission and supply-chain policy
scripts/        local validation and guarded operations
docs/           design decisions, runbooks, and recovery drills
```

## Using it

Run `make help` for the available checks and guarded operations. Before the first
bring-up, work through [the setup list](docs/setup.md), then follow the
[bring-up checklist](docs/bring-up-checklist.md).

## State

The repository is written and passes offline validation.
It has not run on my PCs yet.
I track that work in [the status table](docs/status.md).

[Architecture](docs/architecture.md) · [ADRs](docs/adr/README.md) ·
[Runbooks](docs/runbooks/README.md) · [DR drills](docs/dr/README.md)

Licensed under the [MIT License](LICENSE).
