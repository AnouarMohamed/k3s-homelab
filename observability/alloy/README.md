# Grafana Alloy

Two Alloy replicas discover Kubernetes pods, parse CRI logs, and send them to Loki.
The deployment watches the API with bounded RBAC and has no host log mounts. Operate it
through Argo CD; render and lint it with `make validate-observability`.
