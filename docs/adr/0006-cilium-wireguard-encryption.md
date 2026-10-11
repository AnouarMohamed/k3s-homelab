# Use Cilium WireGuard for pod-traffic encryption

## Status

Accepted

## Context

Traffic crosses a shared home LAN between the three Kubernetes servers. The cluster
needs transparent encryption without introducing a service mesh solely for transport
security. Administrator remote access is a separate Cloudflare WARP decision.

## Decision

Enable Cilium's WireGuard mode with `encryption.enabled=true` and
`encryption.type=wireguard`. Keep `nodeEncryption=false`: the supported, required scope
is eligible pod traffic, while host-network traffic continues to rely on application
TLS and the trusted LAN. The Ansible role loads the kernel module and opens UDP 51871
only between configured cluster nodes.

## Consequences

- Cilium owns key rotation and the `cilium_wg0` interfaces.
- MTU and throughput need hardware measurement after the overlay and encryption
  overhead are active.
- Hubble can diagnose policy and flow behavior, but payloads remain encrypted on the
  underlay.
- WARP remains the private administrator access path and must not be described as the
  same encryption layer.
