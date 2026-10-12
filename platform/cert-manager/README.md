# cert-manager

This directory installs the digest-pinned cert-manager chart and declares staging
and production ACME issuers. DNS-01 uses a scoped Cloudflare API token supplied by
the encrypted edge-secrets application. The wildcard certificate is stored only
in the `gateways` namespace.

Production issuance is intentionally impossible until the central ACME email,
domain, and encrypted token placeholders are replaced.

Operate through the `cert-manager` Argo CD Application. Test offline with
`make validate-edge`; on hardware, inspect the two ClusterIssuers and the wildcard
Certificate using the commands in `docs/VERIFY_ON_HARDWARE.md`.
