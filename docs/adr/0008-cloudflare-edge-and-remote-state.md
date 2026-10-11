# ADR 0008: Cloudflare edge and encrypted remote state

- Status: Accepted
- Date: 2026-10-11

## Context

The platform must publish selected services without an inbound router port and
must provide private administration from enrolled devices. OpenTofu state for a
Tunnel contains a reusable connector token and therefore cannot be committed or
left on a workstation.

## Decision

Use a remotely managed Cloudflare Tunnel with two in-cluster cloudflared
connectors. Cloudflare owns public TLS at the edge; the tunnel forwards only to
the Cilium public Gateway service. A Cloudflare private-network route carries the
single centrally configured CIDR for WARP clients. Cilium WireGuard remains
independent and encrypts pod traffic between cluster nodes.

Use the configured S3 service as an encrypted, versioned OpenTofu backend with
locking. Backend credentials and parameters are runtime inputs. CI may validate
and plan but never applies. Tunnel token transfer to Kubernetes occurs only by a
human who immediately SOPS-encrypts it.

## Consequences

No home-router port is opened. Public DNS and the limited test CNAME are owned by
OpenTofu, avoiding two controllers fighting over a tunnel record. external-dns
is deployed for explicit, annotation-selected Gateway routes but owns no Phase 4
record. Loss of Cloudflare affects remote entry but not LAN administration.
