# Sloth

Sloth converts declarative service-level objectives into Prometheus recording and
alerting rules. The first SLO covers Prometheus API availability at 99.9% over 30 days.
Inspect generated rules in Prometheus and validate the CR and controller offline with
`make validate-observability`.
