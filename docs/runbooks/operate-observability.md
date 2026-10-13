# Operate the observability stack

## Routine checks

Check Argo CD health first, then Prometheus targets and rules, Alertmanager status,
Grafana data sources, Loki readiness, Tempo readiness, and the OpenTelemetry Collector.
Review persistent-volume capacity weekly. Prometheus retains 15 days up to 18 GB, Loki
retains seven days, and Tempo retains 48 hours; adjust only after measuring ingestion.

## Safe changes

Change chart versions, image digests, retention, and resources in Git. Run
`make validate-observability`, review rendered differences, and let Argo CD reconcile.
Do not edit dashboards or alert routes only in the UI because Git remains authoritative.

## Query path

Grafana reads metrics from Prometheus, logs from Loki, and traces from Tempo. Alloy
collects Kubernetes pod logs. Applications send OTLP traces to the OpenTelemetry
Collector, which batches and forwards them to Tempo. Blackbox exporter probes only
specific internal health endpoints.

## Recovery

If a single telemetry backend is unavailable, keep application traffic running and
repair that backend through GitOps. Restore its PVC only when the data is worth more
than the recovery time; telemetry loss does not justify risking application volumes.
Notification credentials are runtime secrets in OpenBao and must never be printed in
logs or copied into the repository.
