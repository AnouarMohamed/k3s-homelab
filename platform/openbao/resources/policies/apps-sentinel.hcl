path "secret/data/apps-sentinel/*" {
  capabilities = ["read"]
}
path "secret/metadata/apps-sentinel/*" {
  capabilities = ["read", "list"]
}
