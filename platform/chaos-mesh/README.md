# Chaos Mesh

Chaos Mesh provides controlled fault injection for the sacrificial `chaos-testing`
namespace. The controller's namespace filter is enabled, and only that namespace has
the required injection annotation. The dashboard and DNS server are disabled.

Argo CD installs the controller and inert target workload. Experiments are deliberately
excluded from GitOps and require the guarded `make test-chaos` command. Validate with
`make validate-chaos-dr`.
