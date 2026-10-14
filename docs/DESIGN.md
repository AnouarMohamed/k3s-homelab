---
name: Homelab Operations
description: A calm, incident-focused Grafana workspace for operating and validating the homelab.
spacing:
  panel-gap: "8px"
  section-gap: "24px"
---

# Design System: Homelab Operations

## 1. Overview

### Creative North Star

"The Quiet Flight Deck"

The dashboard should read like an instrument panel designed for one attentive operator.
Current user impact comes first, likely causes follow, and detailed platform telemetry is
available through deliberate drill-downs. Density is useful only when the reading order
remains obvious in a 16:9 screenshot.

Grafana's native theme, typography, navigation, focus treatment, and interaction patterns
remain authoritative. The repository controls panel hierarchy, semantic status, units,
thresholds, descriptions, links, and query behavior. It does not maintain a parallel
visual skin.

**Key Characteristics:**

- User impact before infrastructure inventory.
- Predictable 24-column layout with visible operational sections.
- Text-supported status using value mappings and explicit titles.
- Native Grafana interactions with no decorative motion.
- Honest empty and no-data states.

## 2. Colors

Grafana's active theme supplies surfaces and text. Dashboard JSON uses semantic threshold
roles only: green for healthy, orange for degraded, and red for critical. Every colored
state is reinforced by a title, value mapping, or legend.

**The Signal Rule.** Color communicates a condition, never decoration. Healthy green is
quiet; orange and red are reserved for states that require attention.

**The Theme Rule.** Do not hard-code page backgrounds, panel surfaces, or body text
colors. They must remain compatible with Grafana's light and dark themes.

## 3. Typography

**Display Font:** Grafana native interface font
**Body Font:** Grafana native interface font
**Label/Mono Font:** Grafana native monospace font for query and identifier values

**Character:** Compact, familiar, and legible. Type establishes priority through native
panel titles, section rows, descriptions, and restrained stat sizing.

### Hierarchy

- **Headline:** Dashboard title and live time range.
- **Title:** Short panel title phrased as an operational question or condition.
- **Body:** Panel descriptions explain the decision a metric supports.
- **Label:** Legends retain only dimensions needed to identify an actionable source.

**The Plain-Language Rule.** Use “Nodes ready” and “Critical alerts firing”, not exporter
or PromQL terminology, in visible titles.

## 4. Elevation

The workspace is flat by default. Grafana's native panel surfaces and separators provide
all required depth; custom shadows and translucent overlays are prohibited.

**The Native Surface Rule.** Rows create hierarchy through spacing and order. Do not nest
visual cards inside Grafana panels.

## 5. Components

### Status panels

- Use compact stat panels only for current conditions with an actionable threshold.
- Pair semantic color with a visible word, count, percentage, or unit.
- Treat no data as unknown, never healthy.

### Trend panels

- Use time series for rate, latency, saturation, and error trends.
- Keep legends in a table only when the source dimension matters during diagnosis.
- Draw thresholds only where an operational boundary is defined.

### Section rows

- Order sections as user experience, delivery, compute, network, and data protection.
- Collapse secondary diagnostic sections when they are not part of the screenshot.

### Dashboard links

- Use native dashboard links for detail views and runbook links for response actions.
- Preserve the active time range when navigating between dashboards.

## 6. Do's and Don'ts

### Do

- **Do** make availability, latency, errors, saturation, recovery, security, or delivery
  the reason for every panel.
- **Do** use correct units, concise descriptions, semantic thresholds, and readable
  legends.
- **Do** design the overview to remain legible in a 16:9 screenshot.
- **Do** expose missing telemetry as unknown or no data.
- **Do** provide drill-down links instead of crowding the overview.

### Don't

- **Don't** use a neon security-operations-center aesthetic.
- **Don't** use decorative gauges, maps, or vanity totals.
- **Don't** create a wall of equal-weight cards.
- **Don't** communicate status through color alone.
- **Don't** add screenshot-only labels or claims that are not backed by live telemetry.
- **Don't** override Grafana's navigation or native interaction behavior.
