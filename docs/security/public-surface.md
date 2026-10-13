# Public surface

The intended public surface is limited to Homelab Sentinel, its status page, and the
temporary Edge traffic whoami route. A read-only Grafana snapshot is optional and disabled
by default. Kubernetes API, Argo CD, Grafana administration, OpenBao, Longhorn, Hubble,
Keycloak administration, databases, and self-hosted application administration are not
public.

Argo CD is rendered as a `ClusterIP`; its Ingress, HTTPRoute, and gRPC route are all
disabled. Argo CD administration therefore requires a trusted local port-forward. Any
later internal route must remain reachable only through WARP private routing.

Cloudflare Tunnel creates outbound connections from the cluster. Administration uses
Cloudflare WARP's WireGuard-based private routing so the router exposes no inbound
port.

Edge traffic publishes `whoami.<configured-domain>` through a
remotely managed Tunnel. OpenTofu owns that CNAME; external-dns is restricted to
directly annotated public-Gateway routes and therefore owns no Edge traffic record. The
public Gateway's LAN load-balancer address is not published to public DNS.

Sentinel adds `status.<configured-domain>` through the same outbound Tunnel. It routes
only to Sentinel's static UI and read-only API. The response contains service name,
state, observation time, and latency for records marked public. Probe URLs, database
credentials, transition messages, internal services, `/metrics`, and both health
endpoints are not routed publicly. Staging uses the internal Gateway and is reachable
only from the private administration path.
