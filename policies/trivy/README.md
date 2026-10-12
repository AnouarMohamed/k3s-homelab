# Trivy Operator

Trivy Operator maintains vulnerability, SBOM, configuration-audit, and RBAC reports.
The two operator replicas are resource-bounded; scanner jobs are capped at two and node
host collection is disabled. Prometheus scrapes its findings metrics and Grafana loads
the repository dashboard.

Run `make validate-policy`; verify real reports with the Phase 8 hardware ledger.
