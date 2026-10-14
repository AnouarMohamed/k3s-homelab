# Observability resources

This component owns platform monitors, actionable alerts, the initial SLO, seven
Grafana dashboards, and namespace network policy. The operations overview orders user
impact before delivery, capacity, network, and recovery signals; detailed dashboards
carry the `drilldown` tag. Inventory-only totals are intentionally excluded.

Every alert links to a checked runbook section. Dashboard JSON and every embedded
PromQL expression are parsed during `make validate-observability`. Longhorn queries
follow the pinned 1.12 metric labels rather than the removed numeric robustness model.
Modify these resources in Git and run that validation before synchronization.
