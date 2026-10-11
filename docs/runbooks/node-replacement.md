# Replace a k3s server node

## Preconditions

- Confirm etcd quorum and a recent off-cluster S3 snapshot from a healthy member.
- Confirm the replacement uses the same node name and central-config address, or update
  `config/homelab.yaml` in Git before provisioning.
- Work locally if WARP or the tunnel depends on the failed node.

## Procedure

1. From a healthy server, inspect membership with `k3s etcd-snapshot ls` and
   `k3s kubectl get nodes -o wide`.
2. Drain the old node when reachable. Delete its Kubernetes Node object only after
   confirming workloads moved.
3. Remove the stale etcd member using the documented k3s member-removal procedure for
   the pinned release; never remove a second member while quorum is degraded.
4. Install Ubuntu Server, static networking, the automation account, and its SSH key.
5. Run `make bootstrap-nodes`. The playbook prepares all hosts but changes only drift;
   the joining server is added through the VIP.
6. Verify the replacement command block in `docs/VERIFY_ON_HARDWARE.md`.

## Rollback

Stop if quorum falls below two members, the VIP is unavailable, or the replacement
name/address differs unexpectedly. Preserve disks and logs. Restore from S3 only under
the separate etcd restore drill; do not improvise a force-new-cluster operation.
