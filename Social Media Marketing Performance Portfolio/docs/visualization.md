# Visualization

## Goal

Build a live Metabase dashboard for cross-platform social media marketing performance analysis.

## Decisions

- Framework: `CRISP-DM`
- Goal tier: `Advanced`
- Tool: `Metabase`
- Deploy target: `VPS`

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
- `vw_sm_post_detail`

## Implemented Visualization Assets

- Local stack file: [docker-compose.yml](../docker-compose.yml)
- Postgres seed SQL: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql)
- Analytics views: [02-analytics-views.sql](../postgres/sql/02-analytics-views.sql)
- Dashboard builder script: [create-metabase-dashboard.ps1](../tools/create-metabase-dashboard.ps1)

## Dashboard Scope

Planned dashboard sections:

1. How to Answer the Core Business Question
2. Platform Overview
3. Post Type Performance
4. Regional Category Performance
5. Posting Time Optimization
6. Hashtag Effectiveness
7. Video and Live Stream Interest
8. Organic vs Sponsored Comparison
9. Key Insights and Suggested Actions
10. Trackable Post Detail

## Local Deploy Status

- Expected URL: `http://localhost:3001`
- Current status: `running`
- PostgreSQL analytics DB seeded successfully with `5,600` post rows
- Metabase container is up on port `3001`
- Local Metabase app was initialized successfully
- Seeded dashboard URL: `http://localhost:3001/dashboard/2`
- Public dashboard URL: `http://localhost:3001/public/dashboard/b9f811ac-fd0a-49c3-b4b6-d4597cc04d13`
- Seeded dashboard card count: `13`
- Dashboard filters are now category-backed field filters instead of plain text variables
- Filter intent: `Platform`, `Region`, `Content Type`, and `Content Category` should render as selectable widgets with multi-select enabled
- Filter source now follows each card's actual source view or table so Metabase injects predicates against valid fields for that specific question

## Validation Status

- Prepared exports generated successfully.
- PostgreSQL seed completed and analytics views loaded.
- Verified `fact_social_post_performance` row count: `5,600`
- Verified `vw_sm_hashtag_effectiveness` row count: `18`
- Metabase health endpoint returns `{"status":"ok"}`
- Dashboard metadata check confirms dashboard `2` with `13` dashcards
- Dashboard parameter metadata now resolves to field-backed category filters with list values tied to each card's actual source view or table
- Public dashboard URL responds with HTTP `200`

## Rebuild Instructions

```powershell
# 1. Regenerate prepared exports
& "C:\Users\khanh\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" tools\build-social-media-prepared-exports.py

# 2. Start the local stack
docker compose up -d

# 3. If you need to reseed the dashboard
.\tools\create-metabase-dashboard.ps1 -Username "you@example.com" -Password "your-password"
```

## Remaining Risks

- The local Metabase app is running, but future dashboard reseeds still depend on a valid Metabase admin login.
- Metabase setup state can delay health readiness for the first boot.
- CTR-focused cards should be interpreted only on trackable rows.
- Multi-select behavior depends on Metabase widget rendering, but the dashboard metadata is now wired correctly to the source fields used by each filtered card.
