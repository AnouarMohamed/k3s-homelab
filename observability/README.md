# Observability Stack

This directory contains manifests for the observability stack deployed via Argo CD, including:

- Prometheus Stack (Prometheus, Grafana, Alertmanager)
- Loki (logging)
- Tempo (tracing)
- Associated dashboards and alerting rules

Each component should have its own subdirectory with Kustomize bases and overlays.