# Recover SSO access

Use this only from the private WARP route. Never expose an administration endpoint
publicly.

## Argo CD break glass

1. Retrieve the local administrator credential through the documented OpenBao operator
   procedure; do not paste it into a shell history.
2. Port-forward locally: `kubectl -n argocd port-forward service/argocd-server 8443:443`.
3. Sign in as the local `admin`, inspect Keycloak and `argocd-oidc`, and repair the OIDC
   secret or realm configuration through Git/OpenBao.
4. Confirm OIDC login, then end the session and rotate the local credential if used.

## Grafana break glass

Port-forward `service/monitoring-grafana` in `monitoring` and use the local credential
held in `grafana-admin`. Local form login is by design retained. Repair the
`monitoring/grafana-oidc` secret or Keycloak client, verify group mapping, then rotate
the emergency password if it was disclosed.

## Keycloak recovery

Check the CNPG cluster and Keycloak health before changing identity data:

```bash
kubectl -n keycloak get cluster keycloak-database
kubectl -n keycloak get pods,externalsecret,httproute
kubectl -n keycloak logs deploy/keycloak --since=15m
```

If the realm is damaged, stop and follow the PostgreSQL PITR drill; do not re-import over
the only copy. If only the bootstrap administrator secret is wrong, update
`secret/keycloak/runtime` in OpenBao, refresh the ExternalSecret, and restart Keycloak.
Realm login, TOTP, group claims, failover, and this procedure are `not run yet`.
