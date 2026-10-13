# Operate Homelab Sentinel

## Probe worker missing

Confirm Prometheus can discover the worker ServiceMonitor before restarting anything.

```bash
kubectl get pods,service,servicemonitor -n apps-sentinel \
  -l app.kubernetes.io/name=sentinel-worker
kubectl logs -n apps-sentinel deploy/sentinel-worker --since=15m
kubectl get cluster sentinel-database -n apps-sentinel
```

If the worker is Ready but the target is absent in Prometheus, inspect the monitoring
NetworkPolicy and ServiceMonitor labels. If it is not Ready, check database health and
the ExternalSecret before reviewing the internal probe configuration. Never expose
the target ConfigMap or worker metrics through the public Gateway.

## API error budget

```bash
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel
kubectl get analysiruns -n apps-sentinel
kubectl logs -n apps-sentinel \
  -l app.kubernetes.io/name=sentinel-api --since=15m --all-containers
```

Abort an active canary when the analysis fails. Use the rollback runbook for a known
bad release. Treat database unavailability separately; rolling back the API does not
repair PostgreSQL.

## Database and backups

The API and worker use a TLS-required CloudNativePG connection. Check the cluster,
scheduled backup, Barman ObjectStore, and ExternalSecret status. Restore only through
the PostgreSQL recovery runbook and retain the original cluster until recovery is
verified.
