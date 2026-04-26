# Design Guidelines

## Dashboard Principles

- Prefer clear business questions over dense KPI walls.
- Use one chart to answer one decision question.
- Separate volume metrics from efficiency metrics.
- Make paid-versus-organic comparisons explicit.
- Keep regional and timing analysis filterable.

## Metabase Conventions

- Use business-readable names.
- Keep filters limited to `Platform`, `Region`, `Content Type`, and `Content Category`.
- Use bar charts for ranking, stacked bars for composition, and line charts for timing patterns.
- Keep drill tables at the bottom of the dashboard.

## Analytical Guardrails

- Do not treat missing `Clicks` or `Click Through Rate` as zero by default.
- Do not overclaim causality from post-level observational data.
- Call out the six-platform reality of the file when presenting findings.
