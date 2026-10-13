# Experimental arm64 phone workers

This is an optional research path, not part of the supported cluster. I would use three
unlockable arm64 phones only after the x86-64 platform and DR drills are verified.

The phones would run a supported Linux userspace, join as k3s agents, carry an
`experimental-phone=true` label and taint, and receive only disposable workloads with
explicit tolerations. They would never host etcd, Longhorn replicas, databases,
identity, secret management, ingress, or monitoring state. Images must publish
`linux/arm64` manifests.

Thermal throttling, battery swelling, USB power stability, kernel/cgroup support,
storage wear, and vendor boot chains make this unsuitable for availability claims. It
needs a separate threat assessment, removal runbook, and measured power/thermal results.
