# Visualization

## Goal

Build a live Metabase dashboard for the Social Media Performance Analytics Challenge using the refreshed Supabase/PostgreSQL-ready data contract.

## Decisions

- Framework: `CRISP-DM`
- Goal tier: `Advanced`
- Tool: `Metabase`
- Deploy target: `VPS`
- Database target: `Supabase`
- Dashboard default: full workbook
- Challenge handling: `scope_segment` remains in the data model, but it is no longer exposed as a dashboard filter
- Geography filters: `country`
- Paid indicator: `promotion_type`

## Prepared-Data Contract Check

Visualization is built on the prepared outputs documented in `data-preparation.md`.

Trusted views for dashboard work:

- `vw_sm_platform_overview`
- `vw_sm_platform_post_type_performance`
- `vw_sm_region_category_performance`
- `vw_sm_posting_hour_performance`
- `vw_sm_posting_day_performance`
- `vw_sm_hashtag_effectiveness`
- `vw_sm_video_live_region_interest`
- `vw_sm_organic_vs_sponsored`
- `vw_sm_regional_ctr_comparison`
- `vw_sm_correlation_driver_inputs`
- `vw_sm_post_detail`
- `vw_sm_executive_overview`
- `vw_sm_platform_format_efficiency`
- `vw_sm_region_category_lift`
- `vw_sm_metric_outlier_posts`
- `vw_sm_posting_time_heatmap`
- `vw_sm_hashtag_growth_leaderboard`
- `vw_sm_video_vs_non_video_performance`
- `vw_sm_numeric_correlation_summary`
- `vw_sm_driver_lift_summary`
- `vw_sm_organic_paid_performance`

## Implemented Visualization Assets

- Local stack file: [docker-compose.yml](D:\VScode\Test\data-visualization-skills\projects\social-media-marketing-performance-portfolio\docker-compose.yml)
- Postgres seed SQL: [01-schema-and-load.sql](D:\VScode\Test\data-visualization-skills\projects\social-media-marketing-performance-portfolio\postgres\sql\01-schema-and-load.sql)
- Analytics views: [02-analytics-views.sql](D:\VScode\Test\data-visualization-skills\projects\social-media-marketing-performance-portfolio\postgres\sql\02-analytics-views.sql)
- Dashboard builder script: [create-metabase-dashboard.ps1](D:\VScode\Test\data-visualization-skills\projects\social-media-marketing-performance-portfolio\tools\create-metabase-dashboard.ps1)

## Dashboard Scope

The dashboard is designed for full-workbook analysis by default. `scope_segment` remains available in the data model for challenge-scope analysis, but `Scope` is no longer shown in the dashboard filter bar.

Global filters:

- Date Range
- Platform
- Country
- Content Category
- Post Type
- Promotion Type
- Hashtag

Current dashboard composition:

- `6` scalar KPI cards
- `12` bar charts
- `3` scatter charts
- `2` line charts
- `4` tables
- `1` explanatory text card for `Correlation Summary`

Implemented dashboard sections:

1. Executive Overview
2. Platform And Format Performance
3. Regional Content Strategy
4. Metric Optimization
5. Posting Time Optimization
6. Hashtag Growth Analysis
7. Video And Live-Stream Trends
8. Correlation And Driver View
9. Organic Versus Paid
10. Strategic Recommendations

## Refresh Completed

- Regenerated prepared CSV exports.
- Added `country`, derived macro `region`, `promotion_type`, `scope_segment`, and `is_challenge_scope`.
- Updated PostgreSQL schema and analytics views for the new data contract.
- Updated Metabase dashboard builder filters and card queries for date range, platform, country, content category, post type, promotion type, and hashtag.
- Added `vw_sm_regional_ctr_comparison` for regional conversion analysis.
- Added `vw_sm_correlation_driver_inputs` for correlation and driver analysis.
- Added advanced analytical views for executive KPIs, platform-format efficiency, regional lift, metric outliers, posting-time heatmap, hashtag growth, video vs non-video performance, numeric correlations, driver lift, and organic vs paid performance.
- Rebuilt the Metabase dashboard into a 28-card analytical workbook aligned to the 10 recommended dashboard sections in `project-plan.md`.
- Added date range, post type, and hashtag filters alongside platform, country, category, and promotion filters.
- Added evidence-linked recommendations that connect findings to business implication, action, and caveat.
- Removed `Scope` and `Region` from the dashboard filter bar per stakeholder feedback.
- Replaced the executive KPI scorecard table with six scalar cards: `Posts`, `Total Engagement`, `Total Views`, `Total Impressions`, `Avg Engagement Rate`, and `Avg CTR`.
- Converted table-heavy analytical cards into chart forms using the chart selection guide: bar charts for category comparison, scatter charts for two-metric relationships, and line chart for posting-hour trend.
- Added a `How to Read Correlation Summary` explanation card under the correlation table so users understand correlation score, row count, interpretation, and causality caveat.

## Local Deploy Status

- Expected URL: `http://localhost:3001`
- Current status: `running`
- Docker CLI is installed.
- Docker Desktop is running.
- PostgreSQL analytics DB seeded successfully with `5,600` post rows.
- Challenge-scope rows: `246`
- Correlation input rows: `5,600`
- Local Metabase health endpoint returns `{"status":"ok"}`.
- Public dashboard URL responds with HTTP `200`.
- Dashboard builder script is updated for the current 7-filter dashboard design.
- Existing public dashboard filters were changed from text inputs to field-backed dropdown filters with checkbox-based multi-select enabled.
- Current public dashboard is populated and reachable. Future dashboard reseeding still requires valid Metabase admin credentials.

## Validation Status

- Prepared exports regenerated successfully.
- Python export script compiles.
- PowerShell dashboard builder parses successfully.
- Repo test suite passes.
- Local Metabase reachability validation passes.
- SQL seed and analytics view creation pass.
- Public dashboard API confirms 7 dashboard filters and 28 dashboard cards.
- String filters use card-backed value sources, `sectionId = string`, stable positions, and `isMultiSelect = true`.
- Playwright UI validation confirms `Scope` and `Region` are removed from the filter bar.
- Playwright UI validation confirms the six scalar metric cards render at the top.
- Playwright UI validation confirms the correlation explanation card renders under `Correlation Summary`.
- Playwright UI validation confirms the dashboard scrolls through the bottom recommendation and post-detail sections without visible query errors.

## Rebuild Instructions

```powershell
# 1. Regenerate prepared exports
& "C:\Users\khanh\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" tools\build-social-media-prepared-exports.py

# 2. Start the local stack
docker compose up -d

# 3. If you need to reseed the dashboard after Metabase is initialized
.\tools\create-metabase-dashboard.ps1 -Username "you@example.com" -Password "your-password"
```

## Remaining Risks

- Docker Desktop must be running before the local Metabase stack can be validated.
- Dashboard reseeding still requires valid Metabase admin credentials.
- CTR-focused cards should be interpreted only on trackable rows.
- Country is derived from the source `Region` field because the workbook has no separate country column.

## Unresolved Questions

- None.
