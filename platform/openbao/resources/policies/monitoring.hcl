path "secret/data/monitoring/*" {
  capabilities = ["read"]
}
path "secret/metadata/monitoring/*" {
  capabilities = ["read", "list"]
}
