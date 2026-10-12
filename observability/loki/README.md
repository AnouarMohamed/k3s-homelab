# Loki

This single-binary Loki instance keeps seven days of pod logs on a Longhorn volume. A
single replica is an explicit small-homelab tradeoff; logs are diagnostic data, not a
durability source. Change retention only after measuring ingestion and validate with
`make validate-observability`.
