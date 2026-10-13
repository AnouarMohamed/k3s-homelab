# Keycloak

Keycloak is the homelab identity provider. A declarative realm import creates the
Argo CD and Grafana OIDC clients, group claims, and mandatory TOTP enrollment. The
service uses a three-instance CloudNativePG cluster and remains reachable only through
the internal Gateway.

Argo CD applies `resources/`. Operate and recover it with
[`docs/runbooks/recover-sso.md`](../../docs/runbooks/recover-sso.md). Validate the
complete Identity and apps surface with `make validate-identity-apps`.
