# 0006-WireGuard Encryption for Cilium

## Status

Accepted

## Context

We are deploying Cilium as the CNI and kube-proxy replacement in our k3s cluster. We want to encrypt the traffic between nodes to ensure confidentiality and integrity of the data as it traverses the untrusted LAN (or any network). Cilium supports transparent encryption using WireGuard, which is a modern, high-performance VPN protocol.

## Decision

We will enable WireGuard transparent encryption between nodes by setting `ipsec.enabled: true` in the Cilium Helm values.

## Consequences

### Positive

- All node-to-node traffic is encrypted automatically, without requiring application changes.
- WireGuard is lightweight and performs well, making it suitable for a homelab environment.
- The encryption is transparent to services and does not require changes to Kubernetes networking concepts.

### Negative

- Adds a small overhead to CPU usage due to encryption and decryption.
- Requires the WireGuard kernel module to be loaded on each node. This may require ensuring the nodes have the necessary kernel headers and packages.
- Encryption does not protect traffic that leaves the cluster (e.g., to external services) unless combined with other measures (like service mesh or application-level TLS).
- Key management is handled automatically by Cilium, but rotating keys may require restarting the Cilium agents.

## Implementation

The decision is implemented by setting the following in `platform/cilium/values.yml`:

```yaml
ipsec:
  enabled: true
```

This will cause Cilium to configure WireGuard interfaces on each node and encrypt all traffic between pods on different nodes.

## Related Decisions

- 0003-cilium-over-flannel.md: This decision selected Cilium as the CNI, which provides the WireGuard encryption feature.

## References

- Cilium Encryption Documentation: https://docs.cilium.io/en/stable/security/encryption/
- WireGuard: https://www.wireguard.com/