variable "aws_region" {
  description = "AWS region for the temporary validation environment."
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "Single availability zone used to model the original single-LAN failure domain."
  type        = string
  default     = "eu-west-1a"
}

variable "ubuntu_ami_id" {
  description = "Pinned Ubuntu Server 24.04 LTS amd64 AMI ID for the selected region."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ubuntu_ami_id))
    error_message = "ubuntu_ami_id must be an explicit AMI ID. Dynamic latest-image selection is forbidden."
  }
}

variable "ssh_public_key" {
  description = "Ephemeral public key used only through an AWS Systems Manager SSH tunnel."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^(ssh-ed25519|sk-ssh-ed25519@openssh.com) ", var.ssh_public_key))
    error_message = "ssh_public_key must be an Ed25519 public key."
  }
}

variable "expires_at" {
  description = "RFC3339 destruction deadline, checked by the guarded apply wrapper."
  type        = string
  nullable    = false

  validation {
    condition     = can(timecmp(var.expires_at, "1970-01-01T00:00:00Z"))
    error_message = "expires_at must be an RFC3339 timestamp."
  }
}

variable "instance_type" {
  description = "Fixed instance size for each of the three temporary k3s servers."
  type        = string
  default     = "m7i-flex.large"

  validation {
    condition     = var.instance_type == "m7i-flex.large"
    error_message = "The evidence environment is cost-bounded to m7i-flex.large. Review the budget before changing it."
  }
}

variable "root_volume_gib" {
  description = "Encrypted gp3 root and Longhorn data capacity per node."
  type        = number
  default     = 200

  validation {
    condition     = var.root_volume_gib == 200
    error_message = "The full-stack validation environment uses exactly 200 GiB per node."
  }
}
