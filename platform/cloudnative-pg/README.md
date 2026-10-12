# CloudNativePG and Barman Cloud

The CloudNativePG operator runs two replicas and delegates WAL archiving and physical
base backups to the supported CNPG-I Barman Cloud plugin. A three-instance verification
cluster proves Longhorn placement and S3 recovery before application databases depend
on the pattern; it is not a production application datastore.

Operate both controllers through the `cloudnative-pg` Argo CD Application. Validate
offline with `make validate-storage`; run backup and restore checks only through the
hardware ledger and storage restore runbook.
