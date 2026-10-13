# Operate self-hosted applications

All three interfaces are private through the internal Gateway. Sentinel is the only
selected-service public status page.

```bash
kubectl -n apps-vaultwarden get deploy,cluster,pvc,scheduledbackup
kubectl -n apps-homepage get deploy,httproute
kubectl -n apps-uptime-kuma get deploy,pvc,httproute
```

For Vaultwarden, verify the CNPG cluster and its latest object-store backup before an
upgrade. Homepage is entirely declarative. Uptime Kuma's SQLite data is on Longhorn and
covered by the daily Velero schedule. Restore testing remains `PENDING HARDWARE`.

Do not enable Vaultwarden signups or its admin endpoint through an ad-hoc manifest.
Make the change in Git, require an internal route, and revert it after the maintenance
window.
