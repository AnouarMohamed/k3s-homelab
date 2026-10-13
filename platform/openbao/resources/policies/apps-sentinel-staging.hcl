path "secret/data/apps-sentinel-staging/*" {
  capabilities = ["read"]
}
path "secret/metadata/apps-sentinel-staging/*" {
  capabilities = ["read", "list"]
}
