# Gateways

Cilium owns separate internal and public Gateway API objects. The internal
Gateway requests the first address in the configured load-balancer pool. The
public Gateway is reachable from the Internet only through cloudflared; no
router port forward is required or supported.

Routes must opt in through a namespace label. TLS references only the wildcard
certificate in this namespace. Split DNS maps internal hostnames to the internal
Gateway address; WARP routes administrators to the configured private CIDR.

Operate through the `gateways` Argo CD Application. `make validate-edge` validates
both objects against the pinned Gateway API schema; acceptance and addresses remain
hardware checks.
