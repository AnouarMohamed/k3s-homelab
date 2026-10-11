# Public surface

The intended public surface is limited to Homelab Sentinel, its status page, and the
temporary Phase 4 whoami route. A read-only Grafana snapshot is optional and disabled
by default. Kubernetes API, Argo CD, Grafana administration, OpenBao, Longhorn, Hubble,
Keycloak administration, databases, and self-hosted application administration are not
public.

Argo CD is rendered as a `ClusterIP`; its Ingress, HTTPRoute, and gRPC route are all
disabled. Phase 3 administration therefore requires a trusted local port-forward. Any
later internal route must remain reachable only through WARP private routing.

Cloudflare Tunnel creates outbound connections from the cluster. Administration uses
Cloudflare WARP private routing so the router exposes no inbound port.
