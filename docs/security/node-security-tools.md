# Node and posture scanner decisions

## kube-bench

kube-bench is not deployed as a privileged DaemonSet. k3s packages control-plane
components differently from a kubeadm cluster, and a continuously privileged scanner
would add host mounts solely to collect periodic evidence. The Phase 8 hardware ledger
instead runs a pinned, reviewed kube-bench release interactively on each node and stores
only the redacted summary. Findings are interpreted alongside the k3s CIS control table.

## Kubescape

Kubescape is not installed. Kyverno, Pod Security Admission, Trivy configuration/RBAC
reports, kube-linter, and the repository validators already cover the current admission
and posture goals. Adding another controller would duplicate findings and consume memory
on the three small nodes. It remains a candidate for an occasional, version-pinned
read-only CI or operator scan if a future control framework requires its evidence.

Neither omission is reported as a passed check. Node-level benchmark output and any
future Kubescape comparison remain `PENDING HARDWARE` or `Not done` as appropriate.
