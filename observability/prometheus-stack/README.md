# Prometheus stack

This pinned chart provides Prometheus, Alertmanager, Grafana, kube-state-metrics, and
node-exporter. It retains metrics for 15 days with an 18 GB cap and uses Longhorn PVCs.
Change the values file in Git, then run `make validate-observability`; use the platform
alert runbook for live incidents.
