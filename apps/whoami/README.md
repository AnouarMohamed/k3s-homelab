# whoami edge test

This deliberately small diagnostic application proves the Edge traffic public path:
Cloudflare DNS and edge, outbound-only tunnel, Cilium public Gateway, then a
namespaced HTTPRoute. It exposes request metadata and must be removed after the
route is evidenced. It has no storage, credentials, or Kubernetes API access.

Operate through the generated `whoami-production` Application. Test offline with
`make validate-edge`; remove the route after the public hardware check is captured.
