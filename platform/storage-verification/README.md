# Storage verification

This bounded test workload owns a one-GiB Longhorn volume and no network access. The
guarded hardware script writes a marker, deletes only this test pod, requires the
replacement to land on another node, and verifies that the marker survived.

Deploy through the `storage-verification` Argo CD Application. Run only
`CONFIRM_STORAGE_TEST=homelab make test-storage-reschedule` after reading the storage
runbook; the result stays `not run yet` until I records it.
