# Power off one node under traffic

Status: **not run yet**

## Preconditions

- Confirm all three nodes, etcd members, Cilium agents, and Sentinel replicas are healthy.
- Confirm a current etcd snapshot and database backup; start the bounded baseline k6
  scenario from a fourth machine.
- Choose one non-VIP-owner node first. Define abort conditions: API unavailable for
  60 seconds, etcd loses quorum, or data writes fail.

## Procedure

1. Record the selected node, VIP owner, rollout state, and k6 start time.
2. Power off exactly the selected physical node; do not stop a second member.
3. Observe VIP, API, workload rescheduling, Longhorn replicas, CNPG, and alerts.
4. Power the node on, wait for it to become Ready, and verify data consistency.

## Rollback

Stop k6, restore power to the selected node, and stop the drill if quorum or storage
health degrades. Do not remove the etcd member during a transient outage.

Expected: the API and status endpoint remain available, etcd retains two-member
quorum, and the returning node converges without manual data repair.

## Results

| Started at | Node | Detect time | Recovery time | Data loss | Evidence | Lessons |
| --- | --- | --- | --- | --- | --- | --- |
