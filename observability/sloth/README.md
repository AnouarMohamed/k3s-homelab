# Sloth

Sloth converts declarative service-level objectives into Prometheus recording and
alerting rules. The first SLO covers Prometheus API availability at 99.9% over 30 days.
Inspect generated rules in Prometheus and validate the CR and controller offline with
`make validate-observability`.

The renderer replaces the pinned chart's wildcard ClusterRole with only the API
operations used by the pinned controller source: list/watch SLOs, update SLO status,
and create/get/update generated PrometheusRules.
