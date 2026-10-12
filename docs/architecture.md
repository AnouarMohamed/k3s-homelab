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

Detailed network, storage, secrets, GitOps, delivery, and backup diagrams are completed
in Phase 12 and linked to observed evidence where available.

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
