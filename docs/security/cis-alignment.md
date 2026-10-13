# CIS alignment for Node provisioning

This is a configuration mapping, not a claim of CIS certification. Runtime evidence is
`not run yet`.

| Area | State | Repository control | Reason when skipped |
| --- | --- | --- | --- |
| Root SSH login | Applied | `sshd-hardening.conf.j2` | not applicable |
| Password SSH login | Applied | `sshd-hardening.conf.j2` | not applicable |
| Host firewall | Applied | `hardening` role and firewall matrix | not applicable |
| Linux auditing | Applied | auditd rules and Kubernetes API audit policy | not applicable |
| Swap | Applied | disabled in fstab and at runtime | not applicable |
| Kernel network settings | Applied | managed sysctl file | not applicable |
| Kubernetes secrets encryption | Applied | k3s `secrets-encryption` | not applicable |
| Kubelet read-only port | Applied | `read-only-port=0` | not applicable |
| Dedicated control-plane nodes | Skipped | all servers are schedulable | Capacity is by design shared in this homelab |
| External etcd | Skipped | k3s embedded etcd | Three embedded members satisfy the intended quorum |
| Automatic API certificate rotation proof | Pending | k3s-managed certificates | Requires runtime observation |
| Full CIS benchmark score | Pending | kube-bench planned in Policy and supply chain | Requires a running cluster |
