# Restore CloudNativePG from object storage

Never restore over the source cluster. Select a completed Barman Cloud base backup and
WAL recovery target, then create a new, temporary Cluster using the documented CNPG-I
recovery source. Keep the original cluster read-only while validating row counts and
application checks against the restored services.

Promotion requires an application-specific change window and rollback plan. Delete the
temporary cluster only after preserving the hardware evidence. The exact recovery
commands and measurements belong in `docs/dr/restore-drill-storage.md`.
