locals {
  homelab = yamldecode(file("${path.module}/../../../config/homelab.yaml"))
  network = local.homelab.spec.network
  nodes   = { for node in local.network.nodes : node.name => node }
}

resource "aws_vpc" "validation" {
  cidr_block           = local.network.privateRouteCidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k3s-homelab-validation"
  }
}

resource "aws_internet_gateway" "validation" {
  vpc_id = aws_vpc.validation.id

  tags = {
    Name = "k3s-homelab-validation"
  }
}

resource "aws_subnet" "validation" {
  availability_zone                   = var.availability_zone
  cidr_block                          = local.network.privateRouteCidr
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  vpc_id                              = aws_vpc.validation.id

  tags = {
    Name = "k3s-homelab-validation"
  }
}

resource "aws_route_table" "validation" {
  vpc_id = aws_vpc.validation.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.validation.id
  }

  tags = {
    Name = "k3s-homelab-validation"
  }
}

resource "aws_route_table_association" "validation" {
  route_table_id = aws_route_table.validation.id
  subnet_id      = aws_subnet.validation.id
}

resource "aws_security_group" "nodes" {
  name                   = "k3s-homelab-validation-nodes"
  description            = "No public ingress; peer and NLB traffic only"
  revoke_rules_on_delete = true
  vpc_id                 = aws_vpc.validation.id

  ingress {
    description = "Cluster peer traffic"
    from_port   = 0
    protocol    = "-1"
    self        = true
    to_port     = 0
  }

  ingress {
    cidr_blocks = [local.network.privateRouteCidr]
    description = "Internal NLB health and Kubernetes API traffic"
    from_port   = 6443
    protocol    = "tcp"
    to_port     = 6443
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Package, registry, S3, Git, and Systems Manager egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = {
    Name = "k3s-homelab-validation-nodes"
  }
}

data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "systems_manager" {
  statement {
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "nodes" {
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json
  name               = "k3s-homelab-validation-nodes"
}

resource "aws_iam_role_policy" "systems_manager" {
  name   = "systems-manager-core"
  policy = data.aws_iam_policy_document.systems_manager.json
  role   = aws_iam_role.nodes.id
}

data "aws_iam_policy_document" "etcd_snapshots" {
  statement {
    actions = ["s3:ListBucket"]
    effect  = "Allow"
    resources = [
      aws_s3_bucket.validation.arn,
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.validation.arn}/k3s-etcd/*"]
  }
}

resource "aws_iam_role_policy" "etcd_snapshots" {
  name   = "k3s-etcd-snapshots"
  policy = data.aws_iam_policy_document.etcd_snapshots.json
  role   = aws_iam_role.nodes.id
}

resource "aws_iam_instance_profile" "nodes" {
  name = "k3s-homelab-validation-nodes"
  role = aws_iam_role.nodes.name
}

resource "aws_key_pair" "validation" {
  key_name   = "k3s-homelab-validation"
  public_key = var.ssh_public_key
}

resource "aws_s3_bucket" "validation" {
  bucket        = local.homelab.spec.storage.s3.bucket
  force_destroy = true

  tags = {
    Name = "k3s-homelab-validation-backups"
  }
}

resource "aws_s3_bucket_public_access_block" "validation" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.validation.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "validation" {
  bucket = aws_s3_bucket.validation.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "validation" {
  bucket = aws_s3_bucket.validation.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "workload_backups" {
  statement {
    actions = ["s3:ListBucket"]
    effect  = "Allow"
    resources = [
      aws_s3_bucket.validation.arn,
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.validation.arn}/*"]
  }
}

resource "aws_iam_user" "workload_backups" {
  name = "k3s-homelab-validation-workload-backups"

  tags = {
    Name = "k3s-homelab-validation-workload-backups"
  }
}

resource "aws_iam_user_policy" "workload_backups" {
  name   = "validation-bucket-only"
  policy = data.aws_iam_policy_document.workload_backups.json
  user   = aws_iam_user.workload_backups.name
}

resource "aws_iam_access_key" "workload_backups" {
  user = aws_iam_user.workload_backups.name
}

resource "aws_instance" "nodes" {
  for_each = local.nodes

  ami                         = var.ubuntu_ami_id
  associate_public_ip_address = true
  availability_zone           = var.availability_zone
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.validation.key_name
  private_ip                  = each.value.address
  subnet_id                   = aws_subnet.validation.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    volume_size           = var.root_volume_gib
    volume_type           = "gp3"
  }

  user_data = <<-USERDATA
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service
    install -d -m 0750 ${local.homelab.spec.storage.longhornDiskPath}
  USERDATA

  tags = {
    Name = each.key
  }

  lifecycle {
    precondition {
      condition     = cidrcontains(local.network.privateRouteCidr, each.value.address)
      error_message = "Every node address must be a usable host address inside privateRouteCidr."
    }
  }
}

resource "aws_lb" "kubernetes_api" {
  internal           = true
  load_balancer_type = "network"
  name               = "k3s-homelab-validation-api"

  subnet_mapping {
    private_ipv4_address = local.network.controlPlaneVip
    subnet_id            = aws_subnet.validation.id
  }

  tags = {
    Name = "k3s-homelab-validation-api"
  }
}

resource "aws_lb_target_group" "kubernetes_api" {
  name        = "k3s-homelab-validation-api"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.validation.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "kubernetes_api" {
  for_each = aws_instance.nodes

  port             = 6443
  target_group_arn = aws_lb_target_group.kubernetes_api.arn
  target_id        = each.value.id
}

resource "aws_lb_listener" "kubernetes_api" {
  default_action {
    target_group_arn = aws_lb_target_group.kubernetes_api.arn
    type             = "forward"
  }

  load_balancer_arn = aws_lb.kubernetes_api.arn
  port              = 6443
  protocol          = "TCP"
}
