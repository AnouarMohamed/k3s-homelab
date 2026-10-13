# Before the first bring-up

I work through this list before I touch the three PCs or any external account.

## Nodes and local values

- [ ] Replace every `CHANGE_ME_*` value in `config/homelab.yaml` with my domain,
  ACME email, LAN and WARP ranges, node addresses and interfaces, control-plane VIP,
  load-balancer range, Longhorn disk path, S3 details, GitLab path, and timezone.
- [ ] Keep the VIP and load-balancer range outside DHCP.
- [ ] Install Ubuntu Server LTS, set static addresses, and add my SSH public key to the
  provisioning account on all three PCs.

## Bootstrap secrets and Git hosting

- [ ] Generate an age identity with `age-keygen`. Store the private identity offline
  and put only its public recipient in `.sops.yaml`.
- [ ] Re-encrypt every bootstrap placeholder with that recipient.
- [ ] Create a GitLab deploy token with `read_repository` only. Encrypt its username
  and token in the repository-credential SOPS file.
- [ ] Add protected and masked CI variables: `GITLAB_PROMOTION_TOKEN` with repository
  write scope, `GHCR_USERNAME`, a GitHub classic PAT in `GHCR_TOKEN` with only
  `write:packages`, and the lowercase owner in `GHCR_NAMESPACE`.
- [ ] Use a protected GitLab runner that permits the pinned Docker-in-Docker service.
  Do not expose it to untrusted forks.
- [ ] Limit the manual production promotion job to my GitLab account.

## Cloudflare and S3

- [ ] Create separate scoped Cloudflare API tokens for DNS and Tunnel management.
- [ ] Configure WARP private-network access.
- [ ] Replace and re-encrypt the cert-manager, external-dns, and cloudflared token
  placeholders. Keep one scoped credential in each namespace.
- [ ] Create the S3 state bucket, enable versioning, and export its scoped credentials.
  Run `make tofu-init`, review `make tofu-plan`, then apply it myself. Do not use local
  state for a real apply.
- [ ] Create the backup bucket and enable versioning. Its endpoint must use HTTPS on
  port 443 unless I change and revalidate the storage egress policies.
- [ ] Re-encrypt the Longhorn, CloudNativePG, and Velero S3 placeholders with three
  separate identities restricted to their own prefixes.

## OpenBao and runtime secrets

- [ ] Follow the OpenBao initialization runbook once. Split five unseal shares across
  separate secure locations and confirm that three shares unseal every voter. Keep the
  initialization record and root token encrypted offline.
- [ ] Run one supervised secret rotation and break-glass exercise. Destroy the
  temporary operator-token file when the non-renewable session ends.
- [ ] Store the Alertmanager webhook as `webhook-url` at
  `secret/monitoring/alertmanager-notification` with the short-lived OpenBao writer.
- [ ] Store the Argo CD notification webhook as `webhook-url` at
  `secret/argocd/notifications`, then revoke the write token.
- [ ] Store Grafana recovery values as `admin-user` and `admin-password` at
  `secret/monitoring/grafana-admin`. Keep the password in my recovery vault.
- [ ] Store Sentinel database values at `secret/apps-sentinel/prod/database` and S3
  values at `secret/apps-sentinel/prod/s3`. Repeat under
  `secret/apps-sentinel-staging/` with separate credentials.
- [ ] Store Keycloak database, bootstrap-admin, and OIDC client values at
  `secret/keycloak/runtime`. Put matching client secrets at `secret/argocd/oidc` and
  `secret/monitoring/grafana-oidc`. Store backup credentials at `secret/keycloak/s3`.
- [ ] Store Vaultwarden database values at `secret/apps-vaultwarden/runtime` and its
  backup credentials at `secret/apps-vaultwarden/s3`.

## Identity and policy

- [ ] Enroll administrator MFA in Keycloak and test the local Argo CD and Grafana
  recovery accounts before I require SSO.
- [ ] Create the first Keycloak administrator in `homelab-admins`, enroll TOTP, test a
  separate `homelab-viewers` account, and run the SSO recovery procedure.
- [ ] Review Kyverno Audit reports, fix every application violation, and follow the
  policy-enforcement runbook before switching GitOps to the Deny overlay.

## Bring-up and later choices

- [ ] Run [the bring-up checklist](bring-up-checklist.md) in order.
- [ ] Run the DR and chaos drills and enter only measurements I observed.
- [ ] After reviewing [capacity](capacity.md), decide whether the cluster has room for
  Paperless-ngx, Immich, Jellyfin, Nextcloud, AdGuard Home, or Gitea.
