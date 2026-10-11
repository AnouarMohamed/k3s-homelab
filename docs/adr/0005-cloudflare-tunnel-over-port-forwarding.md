# Choose Cloudflare Tunnel and WARP over port forwarding

## Status

Accepted

## Context

Selected services need controlled public access and administrators need private remote
access. The router must expose zero inbound ports.

## Decision

Run redundant `cloudflared` connectors that establish outbound-only tunnels. Publish
only explicitly approved HTTPRoutes through the public Gateway. Route the homelab
private network to enrolled administrator devices through Cloudflare WARP and Access;
keep the Kubernetes API, Argo CD, Grafana, storage consoles, and secret systems off the
public route.

Cilium WireGuard remains a separate feature for eligible pod traffic inside the
cluster. It is not the administrator remote-access mechanism.

## Consequences

- Initial bootstrap and tunnel outages require local-LAN administration.
- Cloudflare tokens must be narrowly scoped and kept outside Git.
- Split DNS and route overlap must be tested from both LAN and WARP clients.
- Cloudflare is an external availability and trust dependency for remote access.
- Public and administrative surface tests remain `PENDING HARDWARE/ACCOUNT`.
