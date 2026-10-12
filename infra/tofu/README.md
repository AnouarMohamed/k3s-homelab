# Cloudflare OpenTofu

This root reads the domain and private WARP route only from
`config/homelab.yaml`. It declares a remotely configured, outbound-only
Cloudflare Tunnel; a CNAME for the limited whoami test; and the private-network
route used by enrolled WARP clients. It never configures an inbound router port.

The API token must be supplied as `CLOUDFLARE_API_TOKEN` and scoped to Tunnel,
Zero Trust network route, and DNS editing for the one zone. Account and zone IDs
are supplied as sensitive `TF_VAR_cloudflare_account_id` and
`TF_VAR_cloudflare_zone_id` values.

State contains the tunnel token. Supply S3-compatible credentials only through
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, then initialize the backend from
the central endpoint and bucket. The initializer enables encryption, native S3
lockfiles, and path-style access without putting credentials in files:

```bash
make tofu-init
make tofu-plan
```

The state bucket must have versioning enabled. `AWS_REGION` defaults to
`us-east-1` for S3-compatible services and can be overridden at runtime. Offline
repository validation uses an isolated temporary copy with its backend disabled;
it never contacts the configured endpoint.

After an authorized apply, retrieve the sensitive output explicitly and encrypt
it into `provide-cloudflared-tunnel-token.sops.yaml`. Never redirect a plaintext
token into the repository or a shell history. Applies and state migrations are
manual human operations; Make exposes initialization and planning only.
