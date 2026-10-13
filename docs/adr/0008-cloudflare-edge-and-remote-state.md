# ADR 0008: Cloudflare edge and encrypted remote state

- Status: Accepted
- Date: 2026-10-11

## Context

I need to publish selected services without an inbound router port and retain
private administration from enrolled devices. OpenTofu state for a Tunnel contains
a reusable connector token, so I cannot commit it or leave it on a workstation.

## Decision

I will use a remotely managed Cloudflare Tunnel with two in-cluster cloudflared
connectors. Cloudflare owns public TLS at the edge; the tunnel forwards only to the
Cilium public Gateway service. A Cloudflare private-network route carries the single
centrally configured CIDR for enrolled WARP clients, whose tunnel uses WireGuard.
Cilium WireGuard remains independent and encrypts pod traffic between cluster nodes.

I will use the configured S3 service as an encrypted, versioned OpenTofu backend
with locking. Backend credentials and parameters are runtime inputs. CI may validate
and plan but never applies. I transfer the Tunnel token to Kubernetes only by
immediately SOPS-encrypting it.

## Rejected alternatives

- I rejected router port forwarding because it creates a permanent inbound path.
- I rejected publishing internal Gateway addresses because that leaks private topology
  and still does not provide authenticated administration.
- I rejected local OpenTofu state because it contains a reusable connector token and
  has no durable locking or recovery path.

## Consequences

I do not open a home-router port. OpenTofu owns public DNS and the limited test CNAME,
which prevents two controllers fighting over a tunnel record. I deploy external-dns
for specific, annotation-selected Gateway routes, but it owns no Edge traffic record. The
tradeoff is that a Cloudflare outage removes remote entry while LAN administration
continues to work.
