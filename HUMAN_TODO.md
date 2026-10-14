# Human inputs

These inputs cannot be committed or guessed. They do not block offline repository work.

## Required before AWS planning

- [ ] Log in with AWS IAM Identity Center using profile `homelab-aws` and confirm
  `aws sts get-caller-identity` succeeds. Do not paste credentials into chat.
- [ ] Confirm the AWS region is `eu-west-1`, the USD 150 maximum spend, the seven-day
  lifetime, and the date the USD 180 credit expires.
- [ ] Review the account's current month spend so the validation environment does not
  consume credit reserved for something else.

## Required before public edge and identity tests

- [ ] Put the real domain and ACME email only in `config/homelab.yaml`.
- [ ] Create scoped Cloudflare DNS and Tunnel tokens and keep them out of shell history.
- [ ] Keep the age private identity offline and re-encrypt bootstrap documents for its
  public recipient.
- [ ] Confirm the GitLab deployment source is
  `https://gitlab.com/AnouarMohamed/k3s-homelab` and that `main` is current before Argo
  CD bootstrap.

## Required during runtime initialization

- [ ] Retain OpenBao unseal shares and the initial root token in separate secure
  locations. They are never written to this repository.
- [ ] Enroll the first Keycloak administrator in MFA and verify the local break-glass
  accounts before requiring SSO.
- [ ] Review the saved AWS plan before using `CONFIRM_AWS_SPEND=150`.
- [ ] Run the guarded AWS destruction target after evidence is preserved and confirm no
  `Project=k3s-homelab` resource remains.

The complete platform-specific preparation list remains in [docs/setup.md](docs/setup.md).
