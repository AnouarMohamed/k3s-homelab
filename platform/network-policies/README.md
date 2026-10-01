# Network Policies

This directory contains a reusable Kustomize component for a baseline network policy setup.

The baseline includes:
- Default deny ingress and egress (to isolate the namespace)
- Allow DNS egress (TCP and UDP port 53)
- Allow intra-namespace communication (pods in the same namespace can communicate freely)

## Usage

To use this component in a namespace, create a kustomization.yaml that:

1. Sets the namespace (either via a Namespace resource or by setting the namespace field in kustomization)
2. Includes the base as a base

Example:

```yaml
namespace: my-namespace
bases:
  - ./path/to/platform/network-policies/base
```

Or, if you want to manage the namespace via a Namespace resource:

```yaml
resources:
  - namespace.yaml
bases:
  - ./path/to/platform/network-policies/base
```

See the `example` directory for a complete example.

## Customization

You can add additional network policies by creating more YAML files in the base directory or by overlaying additional policies in your own kustomization.

## Notes

- The default-deny policies are essential for isolation. Without them, the namespace is open to all traffic by default.
- The DNS policy allows egress to any IP on port 53. If you want to restrict DNS to the cluster DNS service, you can modify the policy to use a `to:` block with a `podSelector` that selects the kube-dns/coredns pods or use an `ipBlock` or `namespaceSelector` if you know the DNS service's IP or namespace.
- The intra-namespace policy allows all traffic between pods in the same namespace. If you want to restrict this further, you can modify the policy to use more specific selectors.

## References

- Kubernetes NetworkPolicy: https://kubernetes.io/docs/concepts/services-networking/network-policies/