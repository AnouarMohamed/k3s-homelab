# Architecture

The target is a three-server k3s cluster with embedded-etcd quorum. kube-vip owns the
Kubernetes API virtual address. Cilium replaces kube-proxy, assigns LAN service
addresses, implements Gateway API, and encrypts eligible cross-node traffic.

```mermaid
flowchart LR
  GitLab[GitLab repository and CI] --> Argo[Argo CD]
  Admin[Administrator via Cloudflare WARP] --> Tunnel[Cloudflare Tunnel]
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

Detailed network, storage, secrets, GitOps, delivery, and backup diagrams are completed
in Phase 12 and linked to observed evidence where available.
