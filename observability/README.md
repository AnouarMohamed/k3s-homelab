# Observability

This stack keeps metrics, logs, traces, probes, dashboards, SLOs, and notifications in
Git. Prometheus, Alertmanager, and Grafana come from kube-prometheus-stack; Alloy sends
pod logs to Loki, and the OpenTelemetry Collector sends traces to Tempo.

Argo CD renders each pinned chart through the repository renderer. Run
`make validate-observability` for deterministic Helm rendering, CRD schema validation,
Prometheus rule checks, dashboard JSON parsing, and workload policy checks. Runtime
signal delivery remains `PENDING HARDWARE` until the verification ledger is completed.
