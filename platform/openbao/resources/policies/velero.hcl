path "secret/data/velero/*" {
  capabilities = ["read"]
}
path "secret/metadata/velero/*" {
  capabilities = ["read", "list"]
}
