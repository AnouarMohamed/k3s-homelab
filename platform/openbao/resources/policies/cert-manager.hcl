path "secret/data/cert-manager/*" {
  capabilities = ["read"]
}
path "secret/metadata/cert-manager/*" {
  capabilities = ["read", "list"]
}
