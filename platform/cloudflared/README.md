# cloudflared

Two digest-pinned cloudflared replicas maintain outbound-only connections to a
remotely managed tunnel. The encrypted token is mounted as a read-only file,
pods have no Kubernetes API token, and availability is spread across nodes.

The only public hostname in Phase 4 is the temporary whoami route. Tunnel
configuration, DNS, and the private WARP route are declared in OpenTofu.
