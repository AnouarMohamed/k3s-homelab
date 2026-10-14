# Operate the temporary AWS validation environment

## Scope

This environment exists only long enough to execute the bring-up checks, run a
seven-day telemetry growth observation, capture evidence, and test destruction. It
does not prove kube-vip ARP ownership or Cilium L2 announcements because AWS VPC does
not provide the broadcast behavior used by the physical LAN.

## Local inputs

Authenticate with AWS IAM Identity Center and keep credentials outside the repository:

```bash
aws configure sso --profile homelab-aws
aws sso login --profile homelab-aws
export AWS_PROFILE=homelab-aws
export AWS_REGION=eu-west-1
aws sts get-caller-identity
```

Create an ephemeral key and resolve a specific Canonical Ubuntu Server 24.04 amd64 AMI.
Do not use a `latest` image selector in OpenTofu.

```bash
install -d -m 0700 .runtime/aws-validation
ssh-keygen -t ed25519 -N '' -f .runtime/aws-validation/id_ed25519
export AWS_VALIDATION_SSH_PUBLIC_KEY_FILE="$PWD/.runtime/aws-validation/id_ed25519.pub"
export AWS_VALIDATION_SSH_PRIVATE_KEY_FILE="$PWD/.runtime/aws-validation/id_ed25519"
export AWS_VALIDATION_AMI_ID="$(make --silent aws-validation-resolve-ami)"
export AWS_VALIDATION_EXPIRES_AT=REPLACE_WITH_RFC3339_WITHIN_SEVEN_DAYS
```

The resolver reads Canonical's public Ubuntu Noble parameter, verifies the returned
image belongs to Canonical account `099720109477`, and emits a concrete AMI ID. Record
that ID with the plan; OpenTofu never receives the moving parameter name.

Install the checksum-pinned AWS Session Manager plugin before node provisioning and
record its observed version in `PROGRESS.md`:

```bash
make aws-validation-tools
.tools/bin/session-manager-plugin --version
```

## Plan and apply

```bash
make aws-validation-init
make aws-validation-plan
tofu show .cache/aws-validation/validation.tfplan
CONFIRM_AWS_SPEND=150 make aws-validation-apply
```

The plan must contain exactly three `m7i-flex.large` instances, three encrypted 200 GiB
gp3 root volumes, one internal Network Load Balancer, one versioned encrypted S3 bucket,
and no public security-group ingress. This type is x86-64, provides 2 vCPUs and 8 GiB of
memory, and is eligible for the account's AWS Free plan. Stop if the reviewed regional
estimate approaches the USD 150 ceiling.

## Access and bootstrap boundary

The instances initiate Systems Manager sessions outbound. SSH runs inside an SSM
tunnel and uses the generated private key; there is no internet-facing SSH rule. K3s
uses the EC2 instance role for S3 snapshots, so this path does not create persistent
AWS access keys. The AWS Ansible inventory skips kube-vip, uses the internal NLB DNS
name as the shared k3s API endpoint, and retains the configured private node addresses.

```bash
make aws-validation-bootstrap-nodes
make aws-validation-kubeconfig
```

If a removed initial etcd member reports a tombstone, rejoin only after confirming the
other two servers are active. The successful wrapper records an ignored local marker so
future idempotence runs retain the rejoin configuration:

```bash
AWS_VALIDATION_REJOIN_INITIAL_SERVER=true make aws-validation-bootstrap-nodes
```

The workstation cannot route directly to the internal NLB. Kubernetes access therefore
uses an SSM port-forwarding session to `pc-1`. Keep the session terminal separate from
the test terminal and never commit its generated kubeconfig.

Start the foreground tunnel in terminal one:

```bash
make aws-validation-kube-tunnel
```

Then install Cilium from terminal two. AWS cannot carry the LAN ARP announcements, so
this wrapper disables L2 announcements and omits the LAN-only IP pool and announcement
objects while retaining kube-proxy replacement, Hubble, Gateway API, and WireGuard.

```bash
make aws-validation-bootstrap-cni
export KUBECONFIG="$PWD/.runtime/aws-validation/kubeconfig"
kubectl wait node --all --for=condition=Ready --timeout=10m
```

## Evidence and expiration

Tag inspection and cost review are daily tasks:

```bash
tofu -chdir=infra/tofu/aws-validation output
aws ec2 describe-instances \
  --filters Name=tag:Project,Values=k3s-homelab Name=instance-state-name,Values=running
aws ce get-cost-and-usage \
  --time-period Start=REPLACE_START,End=REPLACE_END \
  --granularity DAILY --metrics UnblendedCost
```

The `ExpiresAt` tag is a deadline, not an automatic spending control. Finish evidence
capture early and destroy immediately rather than waiting for the deadline.
The plan wrapper retains the non-secret OpenTofu inputs under the ignored
`.runtime/aws-validation` directory so destruction still works after the deadline or
after opening a fresh shell.

## Destruction

Preserve redacted screenshots, command summaries, and required hashes first. Then the
human operator runs the guarded destruction target and confirms that no tagged resource
remains:

```bash
CONFIRM_AWS_DESTROY=homelab-validation make aws-validation-destroy
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=k3s-homelab
```

Delete `.runtime/aws-validation` only after the cluster and bucket are confirmed gone.
The local state is required to perform a complete destroy.
