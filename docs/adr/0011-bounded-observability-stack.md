# ADR 0011: Use a bounded LGTM observability stack

## Context

The three-node cluster needs correlated metrics, logs, and traces without consuming the
capacity reserved for applications and backups. The stack also needs declarative
dashboards, actionable alert links, and a service-level objective that can be reviewed
in Git.

## Decision

I use kube-prometheus-stack for Prometheus, Alertmanager, Grafana, node-exporter, and
kube-state-metrics. Alloy sends pod logs to a single-binary Loki instance. Applications
send OTLP traces to two OpenTelemetry Collector replicas, which forward to a
single-binary Tempo instance. Blackbox exporter performs only directly configured
internal probes, and Sloth turns SLO resources into Prometheus rules.

Prometheus keeps 15 days with an 18 GB limit, Loki keeps seven days, and Tempo keeps
48 hours. Prometheus and Alertmanager run multiple replicas where the upstream operator
supports it. Loki and Tempo remain single replica because telemetry is less durable
than application data and the cluster is capacity constrained. All interfaces remain
internal; OpenBao supplies separate Alertmanager and Argo CD notification destinations.

## Rejected alternatives

- I rejected an external hosted telemetry service because the objective is to operate
  and demonstrate the full local signal path without exporting private cluster data.
- I rejected Elasticsearch because its resource cost is disproportionate for three
  small nodes and Loki fits the log-query requirement.
- I rejected direct application-to-Tempo export because the collector provides a
  stable OTLP endpoint, memory limiting, batching, and a future policy boundary.
- I rejected long telemetry retention because it competes with application PVCs and
  does not replace backup or audit data.

## Tradeoffs

Single-replica Loki and Tempo can lose recent telemetry during failure or rescheduling.
The selected upstream Tempo chart is deprecated, so it must move to the supported
distributed chart before scaling beyond this bounded deployment. Node-exporter needs
host namespaces and read-only host mounts, requiring the exact security exception in
the infrastructure checklist. Retention must be tuned from measured ingestion on hardware,
not assumed from offline rendering.
