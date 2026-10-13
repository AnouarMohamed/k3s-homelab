# Cloudflare WARP WireGuard administration

## Preconditions

- Replace the central domain, private route CIDR, ACME email, and network values.
- Create least-privilege Cloudflare API tokens and keep them outside Git.
- Enroll the administrator device in the intended Zero Trust organization.
- Confirm the private CIDR does not overlap the client network.

## Provision

1. Initialize the encrypted S3 backend as documented in `infra/tofu/README.md`.
2. Review a saved OpenTofu plan and apply it manually.
3. Encrypt the tunnel token and DNS token into the three SOPS placeholders.
4. Synchronize edge-secrets, Gateways, cert-manager, external-dns, cloudflared,
   then the whoami application in wave order.
5. Configure split DNS so `internal.<domain>` resolves through the homelab DNS
   service over WARP. Do not publish internal Gateway addresses publicly.

## Verify on hardware

```bash
cloudflared tunnel info homelab
kubectl -n cloudflare get pods -l app.kubernetes.io/name=cloudflared -o wide
kubectl -n gateways get gateway internal public
curl --fail --show-error https://whoami.example.invalid/health
```

Replace the documentation hostname for the real check. Verify WARP can reach the
internal Gateway while a non-enrolled Internet client cannot. Record evidence in
`docs/bring-up-checklist.md`; do not mark it complete from repository validation.

## Revoke

Revoke the connector token in Cloudflare, rotate both SOPS secrets, and restart
cloudflared. Removing the private route or Tunnel is a reviewed manual OpenTofu
change, not a repository teardown command.
