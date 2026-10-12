path "secret/data/argocd/*" {
  capabilities = ["read"]
}
path "secret/metadata/argocd/*" {
  capabilities = ["read", "list"]
}
