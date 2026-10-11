# Baseline network-policy component

The `components/default-deny` Kustomize component selects every pod in the consuming
namespace and:

- denies ingress and egress by default;
- permits DNS only to labeled kube-dns pods in `kube-system`; and
- permits pod-to-pod traffic inside the same namespace.

Consumers add the component to their own `kustomization.yaml` under `components:`.
There is deliberately no example namespace and no cluster-wide policy: every workload
must opt in through its real namespace overlay, then add only its required cross-
namespace and external egress rules.
