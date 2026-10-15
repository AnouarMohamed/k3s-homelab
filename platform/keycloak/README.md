# Keycloak

Keycloak is the homelab identity provider. A declarative realm import creates the
Argo CD and Grafana OIDC clients, group claims, and mandatory TOTP enrollment. The
service uses a three-instance CloudNativePG cluster and remains reachable only through
the internal Gateway.

The pinned stock image performs Quarkus augmentation under `/opt/keycloak/lib` during
startup, so its root filesystem is writable. The exact exception and compensating
controls are recorded in
[`docs/security/policy-exceptions.md`](../../docs/security/policy-exceptions.md).

Argo CD applies `resources/`. Operate and recover it with
[`docs/runbooks/recover-sso.md`](../../docs/runbooks/recover-sso.md). Validate the
complete Identity and apps surface with `make validate-identity-apps`.
