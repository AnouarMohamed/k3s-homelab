output "tunnel_id" {
  description = "Cloudflare Tunnel identifier used by the public CNAME."
  value       = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
}

output "tunnel_token" {
  description = "Sensitive token to encrypt into the cloudflared SOPS Secret."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.homelab.token
  sensitive   = true
}
