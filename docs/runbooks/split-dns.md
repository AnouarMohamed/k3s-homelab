# Split DNS for internal services

## Goal

Internal service names under `internal.<configured-domain>` resolve to the internal
Cilium Gateway only for trusted LAN and enrolled WARP clients. Public resolvers must
not receive the Gateway's private address.

## Configure

1. Create the wildcard internal-zone record in the existing LAN DNS service, using
   the first load-balancer address from `config/homelab.yaml` as its value.
2. Configure Cloudflare Zero Trust Local Domain Fallback for the internal subdomain
   to the LAN DNS resolver reachable through the declared private Tunnel route.
3. Keep public DNS ownership in OpenTofu or explicitly annotated external-dns routes.
   Never create a public wildcard for the internal subdomain.
4. Enroll the administrator device and confirm its WARP connection uses the intended
   Zero Trust organization before testing administration endpoints.

## Verify

```bash
dig +short "service.internal.${DOMAIN}" @"${LAN_DNS_SERVER}"
dig +short "service.internal.${DOMAIN}" @1.1.1.1
curl --fail --show-error "https://service.internal.${DOMAIN}/healthz"
```

Expected: LAN DNS and the enrolled WARP client return the configured internal Gateway
address. A public resolver returns no private address. The HTTPS check succeeds only
from a trusted path. Record real observations in `docs/VERIFY_ON_HARDWARE.md`.

## Failure and rollback

If names resolve publicly or overlap a client network, remove the Local Domain
Fallback entry and the LAN wildcard, then investigate before restoring them. LAN
administration by explicit address remains the break-glass path; no router port is
opened.
