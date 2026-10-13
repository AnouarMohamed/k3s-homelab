# Cilium networking

Cilium `1.20.2` replaces kube-proxy and provides the CNI, Gateway API controller, LB
IPAM, L2 announcements, Hubble, and WireGuard pod-traffic encryption. The chart is
referenced by immutable OCI digest in `dependencies.env`; its built-in workload images
also default to digests.

`configure-cilium.yaml` contains only verified chart fields. The API VIP, node
interfaces, and LB range are substituted from `config/homelab.yaml` in memory by
`scripts/render-config.sh`. No rendered private address is written into Git.

Run `make validate-cni` for checksum verification, two identical Helm/Kustomize
renders, Helm lint, strict kubeconform validation, CRD-schema validation, and
kube-linter. Run `make bootstrap-cni` only against the intended hardware cluster. It
installs the checksum-pinned Gateway API standard CRDs before installing Cilium, then
applies the IPAM and L2 resources.

Hubble UI has no public or internal Gateway route in this setup. Access is local-only
through an authenticated administration session and temporary port forwarding.
