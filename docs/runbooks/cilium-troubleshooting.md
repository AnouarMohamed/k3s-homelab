# Cilium Troubleshooting Runbook

This runbook provides common troubleshooting steps for Cilium in a Kubernetes cluster.

## Table of Contents

1. [Checking Cilium Status](#checking-cilium-status)
2. [Verifying Node Connectivity](#verifying-node-connectivity)
3. [Checking Hubble Observability](#checking-hubble-observability)
4. [LoadBalancer Service Issues](#loadbalancer-service-issues)
5. [Gateway API Issues](#gateway-api-issues)
6. [WireGuard Encryption Issues](#wireguard-encryption-issues)
7. [Common Error Messages](#common-error-messages)
8. [References](#references)

## Checking Cilium Status

To check the status of Cilium components, run:

```bash
cilium status
```

For a more detailed status, including the status of each node, use:

```bash
cilium status --verbose
```

To wait for all components to be ready, use:

```bash
cilium status --wait
```

## Verifying Node Connectivity

Cilium provides a connectivity test tool that can be used to verify connectivity between pods.

To run the connectivity test, use:

```bash
cilium connectivity test
```

This will run a series of tests and report the results.

You can also use the `cilium connectivity` command to test specific scenarios.

## Checking Hubble Observability

If Hubble is enabled, you can use the Hubble CLI to observe network traffic.

To enable the Hubble CLI (if not already installed), follow the instructions in the Cilium documentation.

Once installed, you can run:

```bash
hubble status
```

To observe traffic, use:

```bash
hubble observe
```

You can filter the observation by namespace, pod, port, etc.

## LoadBalancer Service Issues

If a LoadBalancer service is not getting an IP address or is not reachable, consider the following:

1. Check that the CiliumLoadBalancerIPPool resource exists and has available IPs:
   ```bash
   kubectl get ciliumloadbalancerippools
   ```

2. Check that the CiliumL2AnnouncementPolicy exists and is configured correctly:
   ```bash
   kubectl get ciliuml2announcementpolicies
   ```

3. Verify that the nodes are announcing the LoadBalancer IPs on the network. You can use `tcpdump` on the nodes to see if the announcements are being sent.

4. Ensure that the LoadBalancer service is annotated correctly (if using the old annotation style) or that it is using the `LoadBalancer` type.

5. Check the Cilium agent logs for errors related to IP address management or announcements.

## Gateway API Issues

If Gateway API resources are not being processed, consider the following:

1. Verify that the Gateway API CRDs are installed:
   ```bash
   kubectl get crd | grep gateway.networking.k8s.io
   ```

2. Check that the `gatewayAPI.enabled` flag is set to true in the Cilium Helm values.

3. Look at the Cilium operator logs for errors related to Gateway API.

4. Ensure that the Gateway API resources (Gateway, HTTPRoute, etc.) are correctly configured and that they reference valid services.

## WireGuard Encryption Issues

If WireGuard encryption is not working or causing issues, consider the following:

1. Verify that the `ipsec.enabled` flag is set to true in the Cilium Helm values.

2. Check that the `cilium-operator` and `cilium-agent` pods are running and that the WireGuard module is loaded on the nodes.

3. Look at the Cilium agent and operator logs for errors related to WireGuard or IPsec.

4. Ensure that the nodes have the necessary kernel modules for WireGuard (`wireguard`, `ip6_udp_tunnel`, `udp_tunnel`, etc.) and that the kernel version is compatible.

5. Verify that theEncryption is working by checking the traffic between nodes with `tcpdump` or by using `cilium encrypt status`.

## Common Error Messages

- "no available IP addresses in IPPool": This means that the CiliumLoadBalancerIPPool has exhausted its address range. Consider expanding the range or deleting unused LoadBalancer services.

- "Failed to announce IP address": This indicates a problem with the L2 announcements. Check the interface configuration and ensure that the nodes have connectivity to each other on the selected interface.

- "WireGuard error: device not found": This suggests that the WireGuard kernel module is not loaded or that the device creation failed. Check the kernel logs and ensure that the module is installed.

- "Hubble relay not available": Check that the Hubble relay pod is running and that the service is correctly configured.

## References

- Cilium Troubleshooting Guide: https://docs.cilium.io/en/stable/troubleshooting/
- Cilium Knowledge Base: https://docs.cilium.io/en/stable/knowledge-base/
- Gateway API Troubleshooting: https://gateway-api.sigs.k8s.io/references/faq/