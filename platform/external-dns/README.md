# external-dns

The official pinned chart watches only Gateway API HTTPRoutes attached to the
public Gateway. An annotation filter makes DNS publication opt-in, and the
`upsert-only` policy prevents automatic record deletion. A TXT registry protects
records owned by other systems.

The chart intentionally runs one replica because external-dns has no leader
election. Its Cloudflare token is scoped to DNS editing for the single zone.

Operate through the `external-dns` Argo CD Application. `make validate-edge` checks
the chart and NetworkPolicy offline; hardware verification inspects controller logs
for only annotation-selected public-Gateway routes.
