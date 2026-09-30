# Choose Cloudflare Tunnel over Port Forwarding for Remote Access

## Status
Accepted

## Context
We need secure remote access to the homelab's Kubernetes API server and Argo CD UI without exposing ports on the home router. Traditional methods like port forwarding or VPNs have trade-offs in terms of complexity, security, and maintenance.

## Decision
We chose Cloudflare Tunnel (formerly Argo Tunnel) over port forwarding or a standard VPN for the following reasons:
- Cloudflare Tunnel provides a secure, outbound-only connection from the homelab to Cloudflare's edge, eliminating the need to open inbound ports on the router.
- It integrates with Cloudflare Access for zero-trust authentication, allowing us to enforce strong identity-based access controls.
- The tunnel is lightweight and runs as a simple agent (cloudflared) on one of our nodes.
- It supports TCP routing, making it suitable for Kubernetes API (HTTPS) and other services.
- Cloudflare's global network provides low latency and DDoS protection.
- The solution is cost-effective (free tier available) and does not require managing VPN certificates or complex routing.

## Consequences
- We will install cloudflared on one of the homelab nodes (or as a Kubernetes deployment) to create a tunnel for the Kubernetes API server (port 6443) and Argo CD UI (port 443, via an Ingress or Service).
- We will configure Cloudflare DNS to create a CNAME record for our subdomain (e.g., homelab.example.com) pointing to the tunnel.
- Access to the Kubernetes API and Argo CD will be governed by Cloudflare Access policies, requiring authentication via an identity provider (e.g., GitHub, Google, or self-hosted).
- We will document the setup in the runbooks and ensure the tunnel is monitored for connectivity.
- This approach does not encrypt traffic between Cloudflare and the homelab by default; we will rely on mutual TLS or ensure services use HTTPS/TLS (which they do).