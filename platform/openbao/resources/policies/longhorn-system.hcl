path "secret/data/longhorn-system/*" {
  capabilities = ["read"]
}
path "secret/metadata/longhorn-system/*" {
  capabilities = ["read", "list"]
}
