# Cloudflare OpenTofu

This root reads the domain and private WARP route only from
`config/homelab.yaml`. It declares a remotely configured, outbound-only
Cloudflare Tunnel; a CNAME for the limited whoami test; and the private-network
route used by enrolled WARP clients. It never configures an inbound router port.

The API token must be supplied as `CLOUDFLARE_API_TOKEN` and scoped to Tunnel,
Zero Trust network route, and DNS editing for the one zone. Account and zone IDs
are supplied as sensitive `TF_VAR_cloudflare_account_id` and
`TF_VAR_cloudflare_zone_id` values.

State contains the tunnel token. Initialize the S3 backend using runtime-only
`-backend-config` arguments for the central endpoint and bucket, credentials from
the environment, locking, and encryption. Local backend use is validation-only:

```bash
tofu -chdir=infra/tofu init -backend=false
tofu -chdir=infra/tofu validate
tofu -chdir=infra/tofu plan -refresh=false
```

After an authorized apply, retrieve the sensitive output explicitly and encrypt
it into `provide-cloudflared-tunnel-token.sops.yaml`. Never redirect a plaintext
token into the repository or a shell history. Applies and state migrations are
manual human operations; CI and Make only plan.
