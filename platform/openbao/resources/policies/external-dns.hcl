path "secret/data/external-dns/*" {
  capabilities = ["read"]
}
path "secret/metadata/external-dns/*" {
  capabilities = ["read", "list"]
}
