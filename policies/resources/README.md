# Security posture resources

These resources default-deny the Kyverno and Trivy namespaces, permit only the API,
DNS, registry, and Prometheus paths they need, and install a Trivy findings dashboard
and critical-vulnerability alert. The alert links to the response runbook.
