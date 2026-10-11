# Reset k3s nodes

This operation destroys local cluster state. It is only appropriate for a deliberate
full rebuild after backups and recovery material have been verified.

1. Capture the latest etcd and application backup evidence.
2. Confirm the explicit target list from the dynamic inventory.
3. Run `make reset CONFIRM_RESET=homelab` from a local trusted session.
4. Reboot each node before reinstalling so stale mounts and network devices disappear.

The Make target and playbook both require the exact confirmation value. The playbook
removes only its enumerated k3s/CNI paths and does not format disks or touch Longhorn's
separate configured disk path.
