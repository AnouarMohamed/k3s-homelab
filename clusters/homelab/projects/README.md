# Argo CD projects

Projects restrict the exact GitLab repository, destination namespaces, and resource
kinds. The built-in `default` project is deny-all. The GitOps project can manage Argo
CD only in `argocd`; the platform project currently permits Cilium only in
`kube-system`; the applications project permits namespaced workload resources only in
`apps-*`. No project accepts an arbitrary source repository or destination cluster.
