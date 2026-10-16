output "instance_ids" {
  description = "EC2 instance IDs keyed by canonical node name for SSM inventory."
  value       = { for name, instance in aws_instance.nodes : name => instance.id }
}

output "node_private_addresses" {
  description = "Private addresses sourced from config/homelab.yaml."
  value       = { for name, instance in aws_instance.nodes : name => instance.private_ip }
}

output "control_plane_endpoint" {
  description = "Internal Network Load Balancer DNS name used as the temporary k3s API endpoint."
  value       = aws_lb.kubernetes_api.dns_name
}

output "backup_bucket" {
  description = "Versioned bucket name sourced from config/homelab.yaml."
  value       = aws_s3_bucket.validation.id
}

output "backup_endpoint" {
  description = "Regional S3 endpoint used by the temporary environment."
  value       = "https://s3.${var.aws_region}.amazonaws.com"
}

output "workload_backup_access_key_id" {
  description = "Temporary workload backup access-key ID; consume from local state only."
  sensitive   = true
  value       = aws_iam_access_key.workload_backups.id
}

output "workload_backup_secret_access_key" {
  description = "Temporary workload backup secret; consume from local state only."
  sensitive   = true
  value       = aws_iam_access_key.workload_backups.secret
}
