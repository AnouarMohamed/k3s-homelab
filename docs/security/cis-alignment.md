# CIS alignment for Phase 1

This is a configuration mapping, not a claim of CIS certification. Runtime evidence is
`PENDING HARDWARE`.

| Area | State | Repository control | Reason when skipped |
| --- | --- | --- | --- |
| Root SSH login | Applied | `sshd-hardening.conf.j2` | — |
| Password SSH login | Applied | `sshd-hardening.conf.j2` | — |
| Host firewall | Applied | `hardening` role and firewall matrix | — |
| Linux auditing | Applied | auditd rules and Kubernetes API audit policy | — |
| Swap | Applied | disabled in fstab and at runtime | — |
| Kernel network settings | Applied | managed sysctl file | — |
| Kubernetes secrets encryption | Applied | k3s `secrets-encryption` | — |
| Kubelet read-only port | Applied | `read-only-port=0` | — |
| Dedicated control-plane nodes | Skipped | all servers are schedulable | Capacity is intentionally shared in this homelab |
| External etcd | Skipped | k3s embedded etcd | Three embedded members satisfy the intended quorum |
| Automatic API certificate rotation proof | Pending | k3s-managed certificates | Requires runtime observation |
| Full CIS benchmark score | Pending | kube-bench planned in Phase 8 | Requires a running cluster |
