# Human-only tasks

These tasks require Anouar's accounts, hardware, or recovery material. They do not
block repository implementation.

## Before bootstrap

- [ ] Replace every `CHANGE_ME_*` value in `config/homelab.yaml` with the real domain,
  administrator LAN/WARP CIDR, LAN addresses and interfaces, control-plane VIP,
  non-DHCP load-balancer range, Longhorn disk path, S3 endpoint/bucket, and GitLab
  project path.
- [ ] Confirm the VIP and load-balancer range are excluded from DHCP.
- [ ] Install Ubuntu Server LTS, set static node addresses, and add Anouar's SSH public
  key to the automation account on all three PCs.
- [ ] Generate an age identity with `age-keygen`; store the private identity offline and
  put only its public recipient in `.sops.yaml`.
- [ ] Re-encrypt bootstrap placeholder secrets with that recipient.
- [ ] Create a least-privilege GitLab deploy token and CI variables documented in the
  Phase 3 and Phase 9 runbooks.
- [ ] Create scoped Cloudflare API tokens for DNS and Tunnel management and configure
  WARP private-network access.
- [ ] Create the S3 bucket/credentials or authorize OpenTofu to create them.

## During platform bring-up

- [ ] Initialize OpenBao once, distribute unseal key shares to separate secure
  locations, and keep the root token offline after configuration.
- [ ] Configure the Alertmanager notification destination as an OpenBao secret.
- [ ] Enroll administrator MFA in Keycloak and test the local Argo CD/Grafana
  break-glass accounts before enabling SSO-only access.

## Hardware verification

- [ ] Run every command in `docs/VERIFY_ON_HARDWARE.md` in order.
- [ ] Only after observing the expected behavior, update `docs/STATUS.md` from
  `Untested` to `Verified` and add evidence.
- [ ] Execute DR and chaos drills and fill the intentionally empty result tables with
  measured values.
- [ ] Capture the screenshots listed in `docs/img/README.md` after redacting domains,
  LAN addresses, tokens, user identifiers, and browser history.

## Optional capacity decisions

- [ ] After the core platform capacity report exists, choose whether to add
  Paperless-ngx, Immich, Jellyfin, Nextcloud, AdGuard Home, or Gitea.
- [ ] Decide whether to attempt the isolated experimental arm64 phone-worker project.
