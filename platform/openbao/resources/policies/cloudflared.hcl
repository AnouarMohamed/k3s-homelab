path "secret/data/cloudflared/*" {
  capabilities = ["read"]
}
path "secret/metadata/cloudflared/*" {
  capabilities = ["read", "list"]
}
