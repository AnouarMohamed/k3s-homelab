provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "validation"
      ExpiresAt   = var.expires_at
      ManagedBy   = "opentofu"
      Project     = "k3s-homelab"
    }
  }
}
