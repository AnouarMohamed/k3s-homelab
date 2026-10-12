# Human-only tasks

These tasks require Anouar's accounts, hardware, or recovery material. They do not
block repository implementation.

## Before bootstrap

- [ ] Replace every `CHANGE_ME_*` value in `config/homelab.yaml` with the real domain,
  ACME email, administrator LAN/WARP CIDR, WARP private route CIDR, LAN addresses and
  interfaces, control-plane VIP, non-DHCP load-balancer range, Longhorn disk path, S3
  endpoint/bucket, and GitLab project path.
- [ ] Confirm the VIP and load-balancer range are excluded from DHCP.
- [ ] Install Ubuntu Server LTS, set static node addresses, and add Anouar's SSH public
  key to the automation account on all three PCs.
- [ ] Generate an age identity with `age-keygen`; store the private identity offline and
  put only its public recipient in `.sops.yaml`.
- [ ] Re-encrypt bootstrap placeholder secrets with that recipient.
- [ ] Create a GitLab deploy token with `read_repository` only, encrypt its username
  and token into the tracked repository-credential SOPS document, and configure the
  separate Phase 9 CI variables when that phase is implemented.
- [ ] Create scoped Cloudflare API tokens for DNS and Tunnel management and configure
  WARP private-network access.
- [ ] Replace and re-encrypt all three Phase 4 SOPS token placeholders, then confirm
  that the cert-manager, external-dns, and cloudflared namespaces contain only their
  individually scoped credential.
- [ ] Enable versioning on the S3 state bucket, export its narrowly scoped credentials,
  run `make tofu-init`, then review `make tofu-plan` and manually apply it. Never use
  local state for a real apply.
- [ ] Create the S3 bucket and enable versioning. Its endpoint must use HTTPS on port
  443 unless the Phase 5 egress policies are deliberately changed and revalidated.
- [ ] Replace and re-encrypt the Longhorn, CloudNativePG, and Velero S3 credential
  placeholders with three least-privilege identities restricted to their prefixes.

## During platform bring-up

- [ ] Follow the OpenBao initialization runbook exactly once, distribute five unseal
  shares to separate secure locations, verify that three shares can unseal every voter,
  and keep the initialization record and root token encrypted offline.
- [ ] Complete one supervised runtime-secret rotation and break-glass exercise; destroy
  the temporary operator-token file after the non-renewable session ends.
- [ ] Using the short-lived write-only OpenBao operator workflow, store the
  Alertmanager webhook as property `webhook-url` at
  `secret/monitoring/alertmanager-notification`. Pass the value on standard input or
  from a protected file; do not put it in shell history.
- [ ] Store the separate Argo CD notification webhook as property `webhook-url` at
  `secret/argocd/notifications`, then revoke the temporary write token.
- [ ] Store a non-default Grafana break-glass username and generated password as
  properties `admin-user` and `admin-password` at `secret/monitoring/grafana-admin`.
  Keep the password in the recovery vault and never pass it as a shell argument.
- [ ] Enroll administrator MFA in Keycloak and test the local Argo CD/Grafana
  break-glass accounts before enabling SSO-only access.
- [ ] Review Phase 8 Audit reports, resolve every application violation, and use the
  policy-enforcement runbook before changing the GitOps path to the Deny overlay.

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
