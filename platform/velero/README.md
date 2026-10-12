# Velero

Velero stores cluster-resource backups under a dedicated prefix in the configured S3
bucket and uses Longhorn CSI snapshots for persistent volumes. Hourly backups cover the
critical GitOps and storage-verification namespaces; a daily schedule covers the full
cluster. The node agent is intentionally disabled because this phase uses CSI snapshots.

Operate through the `velero` Argo CD Application. Validate with
`make validate-storage`; use the restore runbook and hardware ledger before trusting a
schedule as recoverable.
