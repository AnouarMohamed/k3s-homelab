# Architecture decision records

| ADR | Decision |
| --- | --- |
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions |
| [0002](0002-k3s-over-kubeadm.md) | Use k3s instead of kubeadm |
| [0003](0003-cilium-over-flannel.md) | Use Cilium instead of Flannel |
| [0004](0004-argo-cd-over-flux.md) | Use Argo CD instead of Flux |
| [0005](0005-cloudflare-tunnel-over-port-forwarding.md) | Use Cloudflare Tunnel without router ports |
| [0006](0006-cilium-wireguard-encryption.md) | Encrypt pod traffic with Cilium WireGuard |
| [0007](0007-ksops-bootstrap-secrets.md) | Limit KSOPS to bootstrap secrets |
| [0008](0008-cloudflare-edge-and-remote-state.md) | Manage Cloudflare and remote state with OpenTofu |
| [0009](0009-layered-storage-and-backup.md) | Layer Longhorn, CNPG, Velero, and S3 backups |
| [0010](0010-bootstrap-and-runtime-secrets.md) | Separate bootstrap and runtime secrets |
| [0011](0011-bounded-observability-stack.md) | Use a bounded LGTM observability stack |
| [0012](0012-audit-before-policy-denial.md) | Audit application policy before denial |
| [0013](0013-digest-promotion-and-ghcr-mirroring.md) | Promote digests and mirror packages to GHCR |
| [0014](0014-use-keycloak-for-identity.md) | Use Keycloak with local break glass |
