# Upgrade k3s safely

## Preconditions

- Verify the target k3s release checksum and Cilium compatibility, then update the pin
  and checksum together in `group_vars/all.yaml`.
- Confirm all nodes are Ready, etcd has three healthy members, recent S3 snapshots
  exist, and no Longhorn replica is rebuilding.
- Read the upstream release notes for skipped versions and API removals.

## Procedure

1. Run the Ansible syntax and lint gates locally.
2. Run `make upgrade-k3s`. Joining servers are drained and upgraded serially; `pc-1`
   is upgraded last. A node is always uncordoned after its upgrade attempt.
3. Between nodes, verify API health, etcd membership, Cilium health, and critical
   workloads. Stop on any unexpected state.
4. Run the hardware verification commands and record the observed versions.

Reboot nodes one at a time. Check `/var/run/reboot-required` before each reboot. Wait
for etcd and Longhorn to report healthy before moving to the next node.

## Rollback

Do not downgrade an etcd-backed server in place without confirming upstream downgrade
support. Stop the rollout, retain quorum, and restore the previous repository pin. If
the release changed datastore state incompatibly, use the tested snapshot-restore
procedure instead of replacing binaries blindly.
