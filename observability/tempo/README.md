# Tempo

Tempo stores 48 hours of traces on a Longhorn volume and receives OTLP from the
collector. The upstream monolithic chart is deprecated but remains the bounded choice
for this small cluster; migration to the distributed chart is required before scaling.
Its chart NetworkPolicy is disabled because the pinned template emits invalid YAML;
the monitoring namespace default-deny and explicit allow policy still select the pod.
Validate changes with `make validate-observability`.
