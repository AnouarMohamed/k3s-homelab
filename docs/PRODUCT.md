# Product definition

## Register

This is an operator-facing platform dashboard. It is a working product surface for
running and validating the homelab, not a marketing page or a decorative status wall.

## Primary user

I am the primary user. I use the dashboard while deploying, testing, recovering, and
collecting evidence from the cluster. A recruiter or platform engineer reviewing a
screenshot is a secondary audience and should understand the platform's condition
without needing a verbal explanation.

## Primary job

Within a few seconds, answer:

1. Is the user-facing service available?
2. If it is degraded, which layer is responsible?
3. Is the cluster approaching a resource or recovery limit?
4. Did a deployment, policy event, or infrastructure change cause the condition?
5. Which runbook should I open next?

## Product promise

The dashboard presents a concise operational narrative from user experience through
applications, delivery, compute, network, storage, databases, backups, and security.
Every promoted metric must support an availability, latency, error, saturation,
recovery, security, or delivery decision.

## Personality

Calm, precise, and incident-focused. The interface should feel like a well-organized
instrument panel: dense enough for real operations, quiet enough to scan under pressure,
and explicit about unknown or missing data.

## Anti-references

- No neon security-operations-center aesthetic.
- No decorative gauges, maps, or vanity totals.
- No wall of equal-weight cards.
- No color-only status communication.
- No screenshot-only labels or claims that are not backed by live telemetry.

## Accessibility

- Meet WCAG AA contrast for text and controls.
- Use color-blind-safe severity colors with text or icon reinforcement.
- Do not rely on animation to communicate state.
- Keep panel titles and legends readable in a 16:9 screenshot.
- Preserve keyboard navigation and native Grafana interaction patterns.

## Evidence use

The main overview is composed for both live operations and one recruiter-facing
screenshot. Detailed dashboards remain optimized for diagnosis. Evidence is captured
only from a running cluster and is never synthesized from expected results.

## Non-goals

- Replacing Alertmanager or runbooks.
- Displaying every collected series.
- Acting as a public status page.
- Optimizing for infrastructure cost accounting.
- Hiding absent metrics or failed collectors.
