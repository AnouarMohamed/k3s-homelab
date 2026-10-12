path "secret/data/storage-verification/*" {
  capabilities = ["read"]
}
path "secret/metadata/storage-verification/*" {
  capabilities = ["read", "list"]
}
