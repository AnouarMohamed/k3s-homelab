# ADR 0012: Use Keycloak for identity

## Context

I need one self-hosted OIDC provider for Argo CD and Grafana, group-based authorization,
and administrator MFA. It must survive a node loss and remain recoverable when SSO is
broken.

## Decision

I use Keycloak 26.8.0 with two application replicas and a three-instance
CloudNativePG database. A versioned realm import creates the clients and group claim
mappers. TOTP enrollment is mandatory for every account, which is stricter than the
administrator-only requirement. `homelab-admins` and `homelab-viewers` drive Argo CD
and Grafana roles. Argo CD and Grafana keep local credentials in OpenBao for emergency
access.

## Rejected alternatives

- Authentik is capable, but would add worker and Redis-style moving parts for no needed
  feature advantage here.
- Cloudflare Access as the only identity layer would make local administration depend
  on an external control plane.
- Removing local accounts would turn an identity outage into a platform lockout.

## Tradeoff

Keycloak and PostgreSQL consume more memory than a lightweight proxy. In return I get
standard OIDC, declarative clients, group claims, and a mature recovery model. Realm
import updates existing realms conservatively, so changes must be verified on hardware
and exported before upgrades.
