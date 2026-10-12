path "secret/data/external-secrets/*" {
  capabilities = ["read"]
}
path "secret/metadata/external-secrets/*" {
  capabilities = ["read", "list"]
}
