# cloudflared

Two digest-pinned cloudflared replicas maintain outbound-only connections to a
remotely managed tunnel. The encrypted token is mounted as a read-only file,
pods have no Kubernetes API token, and availability is spread across nodes.

The only public hostname in Phase 4 is the temporary whoami route. Tunnel
configuration, DNS, and the private WARP route are declared in OpenTofu.

Operate through the `cloudflared` Argo CD Application and rotate its connector token
through the SOPS placeholder. `make validate-edge` checks the two-replica workload;
the hardware ledger verifies connector health and node spreading.
