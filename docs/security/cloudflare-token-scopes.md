# Cloudflare credential scopes

Use separate tokens rather than a global API key.

- OpenTofu token: account-scoped Tunnel write, Zero Trust network route write,
  zone read, and DNS write for only the homelab zone.
- DNS controller token: zone read and DNS write for only the homelab zone.
- cloudflared connector token: generated for only the homelab Tunnel.

Token values are never committed. Kubernetes copies are SOPS-encrypted to
my age recipient. OpenTofu state is sensitive because the connector token
is an output; it belongs only in the encrypted, versioned S3 backend.
