# Temporary AWS validation environment

This module creates three short-lived x86-64 EC2 nodes, an internal Network Load
Balancer for the k3s API, encrypted gp3 storage, and outbound Systems Manager access.
It has no public ingress rules. The instances receive temporary public addresses only
for outbound package and registry traffic; those addresses are never emitted as
outputs or committed.

K3s v1.36.5+k3s1 obtains S3 credentials from its MinIO provider chain, so the nodes
use their narrowly scoped EC2 instance role instead of persistent access keys.

This is an evidence environment for the canonical three-PC platform, not a replacement
architecture. AWS VPC networking cannot validate kube-vip ARP ownership or Cilium L2
announcements. Those two checks remain specific to a broadcast-capable LAN.

The wrapper requires a pinned regional Ubuntu 24.04 LTS AMI, an ephemeral Ed25519
public key, a destruction deadline no more than seven days away, and an explicit spend
confirmation. State stays local and ignored for this temporary environment. Keep an
encrypted off-repository copy until destruction is complete.

The validation nodes use `m7i-flex.large`: the largest x86-64, 8 GiB option accepted by
the account's AWS Free plan at the time of the observed deployment attempt.
Each node uses a 200 GiB encrypted gp3 root disk so Longhorn can retain its canonical
three replicas for the full evidence stack. AWS Pricing returned USD 0.088 per
GB-month in `eu-west-1` on 2026-10-14; review the current storage price before apply.

```bash
export AWS_VALIDATION_AMI_ID="$(make --silent aws-validation-resolve-ami)"
make aws-validation-init
make aws-validation-plan
CONFIRM_AWS_SPEND=150 make aws-validation-apply
make aws-validation-bootstrap-nodes
make aws-validation-kubeconfig
```

Keep `make aws-validation-kube-tunnel` running in a separate terminal before using
kubectl or running `make aws-validation-bootstrap-cni`.

Destroy from a trusted terminal when evidence capture is complete:

```bash
CONFIRM_AWS_DESTROY=homelab-validation make aws-validation-destroy
```

The module does not claim that an AWS budget is a hard spending cap. Review the plan's
regional prices and the AWS Billing console before applying.
