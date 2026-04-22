# Visualization

## Goal

Build a live Metabase BI dashboard for FVSD literacy intervention planning.

## Decisions

- Framework: `CRISP-DM`
- Goal tier: `Advanced`
- Tool: `Metabase`
- Deploy target: `VPS`

## Prepared-Data Contract Check

Visualization is built on the prepared outputs documented in `data-preparation.md`.

Trusted views for dashboard work:

- `vw_fvsd_executive_overview`
- `vw_fvsd_school_pressure`
- `vw_fvsd_grade_assessment_mix`
- `vw_fvsd_next_term_forecast`
- `vw_fvsd_assessment_level_distribution`
- `vw_fvsd_assessment_type_distribution`
- `vw_fvsd_assessment_level_group_distribution`
- `vw_fvsd_winter_2023_2024_forecast`
- `vw_fvsd_assessment_level_change`
- `vw_fvsd_average_score_trend`
- `vw_fvsd_term_metrics`
- `vw_fvsd_term_comparison`
- `vw_fvsd_yoy_same_term`
- `vw_fvsd_forecast_baseline_bridge`

## Implemented Visualization Assets

- Local stack file: [docker-compose.yml](../docker-compose.yml)
- Postgres seed SQL: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql)
- Dashboard builder script: [create-metabase-dashboard.ps1](../tools/create-metabase-dashboard.ps1)

## Dashboard Scope

0. Dashboard Guide
   Single narrative table covering FVSD context, section map, intervention tier logic, filter usage, and forecast caveat.
1. Assessment Performance
   Proficiency counts, share mix, score trend, and level changes — all as charts.
2. Intervention Demand
   Tier split, school pressure, grade risk, previous-term delta, and YoY comparison — all as charts.
3. Staffing and Cost Forecast
   Winter `2023 / 2024` teacher and cost projections, executive trend line, program cost, and next-term staffing — all as charts.
4. School Deep Dive
   Filterable detail table. Use the School filter to isolate one school across all terms.
5. Insights and Key Findings
   Five evidence-based findings with theme, evidence, data source, and planning implication.

## Local Deploy

- Expected URL after stack start: `http://localhost:3000`
- Current status: `running`
- Metabase dashboard: `http://localhost:3000/dashboard/5`

## Rebuild Instructions

To rebuild the dashboard from scratch (e.g. after a full stack reset):

```powershell
# 1. Start the stack
docker compose up -d

# 2. Apply the new views (not in the init script — apply manually after first boot)
docker exec fvsd-postgres psql -U metabase -d fvsd_analytics -f /sql/01-schema-and-load.sql

# 3. Deploy dashboard
.\tools\create-metabase-dashboard.ps1 -Username "you@email.com" -Password "yourpass"
```

If updating an existing dashboard in place, pass `-DashboardId 5`.

## Remaining Risks

- The four new views (`vw_fvsd_term_metrics` etc.) are not in the Postgres init script — they must be applied manually after a full volume reset, or the seed SQL must be reloaded explicitly.
- The current forecast is intentionally lightweight and scenario-oriented; do not present Winter `2023 / 2024` numbers as audited actuals.
- `sort_order` helper columns in narrative table cards are visible unless hidden via Metabase column settings in the UI.
