# ADR 0014: Use Keycloak for identity

## Context

I need one self-hosted OIDC provider for Argo CD and Grafana, group-based authorization,
and administrator MFA. It must survive a node loss and remain recoverable when SSO is
broken.

## Decision

I use Keycloak 26.8.0 with two application replicas and a three-instance
CloudNativePG database. A versioned realm import creates clients and group claims. TOTP
enrollment is mandatory for every account. `homelab-admins` and `homelab-viewers` drive
Argo CD and Grafana roles, which retain local break-glass credentials.

## Rejected alternatives

- Authentik would add worker and Redis-style moving parts for no needed advantage.
- Cloudflare Access alone would make local administration depend on an external plane.
- Removing local accounts would turn an identity outage into a platform lockout.

## Tradeoff

Keycloak and PostgreSQL consume more memory than a lightweight proxy. In return I get
standard OIDC, declarative clients, group claims, and a mature recovery model. Realm
changes require hardware verification and an export before upgrades.
