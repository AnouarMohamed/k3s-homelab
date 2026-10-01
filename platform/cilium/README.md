# Cilium Installation

This directory contains the Helm values and Kubernetes manifests for installing Cilium as the CNI and kube-proxy replacement.

## Contents

- `values.yml`: Helm values for the Cilium chart.
- `cilium-lb-ippool.yaml`: CiliumLoadBalancerIPPool resource defining the IP range for LoadBalancer services.
- `cilium-l2-policy.yaml`: CiliumL2AnnouncementPolicy resource defining how LoadBalancer IPs are announced on the network.

## Installation

The Cilium installation is performed via the `bootstrap-cni` Make target, which installs the Gateway API CRDs and then Cilium via Helm.

## Configuration

### Helm Values

The `values.yml` file sets the following key options:

- `kubeProxyReplacement: true` - Replace kube-proxy with Cilium.
- `k8sServiceHost` and `k8sServicePort` - The address and port of the Kubernetes API server (via kube-vip).
- `l2announcements.enabled: true` - Enable L2 announcements for LoadBalancer services.
- `gatewayAPI.enabled: true` - Enable Gateway API support.
- Hubble relay, UI, and metrics are enabled for observability.
- `operator.replicas: 2` - Run two operator replicas for high availability.
- `ipsec.enabled: true` - Enable WireGuard transparent encryption between nodes.
- Resource requests and limits are set for all components to ensure stable operation.

### IP Pool and L2 Announcement Policy

- The `CiliumLoadBalancerIPPool` defines the IP range `192.168.1.240/28` for LoadBalancer services.
- The `CiliumL2AnnouncementPolicy` specifies that these IPs should be announced on the `eth0` interface (as defined in the inventory).

## Notes

- The interface name in the L2AnnouncementPolicy should match the network interface used by the nodes for communication.
- The IP range for the LoadBalancer pool must be free in your LAN and not conflict with any existing devices.
- Adjust the resource values in `values.yml` based on your node capacity and workload.

## References

- Cilium Helm chart: https://helm.cilium.io/
- Gateway API: https://gateway-api.sigs.k8s.io/
- Hubble: https://docs.cilium.io/en/stable/observability/hubble/