# Publish

## Deploy Target

- Tool path: `Metabase`
- Target: `VPS`
- Database target: `Supabase`
- Live dashboard URL: `https://data.youngllilo.works/dashboard/11-social-media-marketing-performance`
- Local validation URL: `http://localhost:3001`
- Local public dashboard URL: `http://localhost:3001/public/dashboard/b9f811ac-fd0a-49c3-b4b6-d4597cc04d13`

## Deployment Assets

- Docker stack: [docker-compose.yml](../docker-compose.yml)
- Database init scripts: [01-create-databases.sh](../postgres/init/01-create-databases.sh), [02-load-social-media-analytics.sh](../postgres/init/02-load-social-media-analytics.sh)
- SQL schema and views: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql), [02-analytics-views.sql](../postgres/sql/02-analytics-views.sql)
- Prepared exports: `docs/assets/exports/`
- Dashboard builder: [create-metabase-dashboard.ps1](../tools/create-metabase-dashboard.ps1)

## Publish Checklist

- `project-brief.md` exists and reflects the Onyx June 2024 challenge.
- `project-plan.md` exists and records CRISP-DM, Advanced, Metabase, VPS, and Supabase.
- `data-preparation.md` exists and reflects the refreshed prepared-data contract.
- `visualization.md` exists and reflects the updated Metabase dashboard direction.
- `publish.md` exists.
- Prepared exports exist under `docs/assets/exports/`.
- `mart-correlation-inputs.csv` exists for driver analysis.
- PostgreSQL schema and analytics views load successfully.
- Local Metabase stack runs at `http://localhost:3001`.
- Public dashboard URL responds with HTTP `200`.
- `.gitignore` excludes local runtime artifacts and sensitive files.

## Supabase Handoff

The SQL model is PostgreSQL-first and can be moved into Supabase with minimal changes.

Recommended hosted path:

1. Load prepared CSV exports into a project-specific Supabase schema.
2. Point hosted Metabase at the Supabase Postgres connection.
3. Ensure Metabase scans the selected schema.
4. Run the dashboard builder script against hosted Metabase after providing admin credentials.

Safe Supabase load command:

```powershell
$env:SUPABASE_DB_URL = "postgresql://USER:PASSWORD@HOST:PORT/postgres?sslmode=require"
.\tools\load-supabase-postgres.ps1 -Schema "social_media_marketing_v2" -Clean
```

The loader intentionally avoids `drop schema public cascade`; use the project schema `social_media_marketing_v2` for the hosted Supabase deployment.

## Metabase Reseed Command

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "http://localhost:3001" `
  -Username "admin@example.com" `
  -Password "your-password" `
  -DatabaseName "Social Media Analytics" `
  -DashboardId 2
```

Hosted Metabase command, when the Supabase database is already registered in Metabase:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://data.youngllilo.works" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId 2 `
  -CollectionId 8 `
  -SqlSchema "social_media_marketing_v2" `
  -NoDashboardFilters
```

Current hosted Metabase target:

- Base URL: `https://data.youngllilo.works`
- Database ID: `2`
- Collection ID: `8`
- Supabase schema: `social_media_marketing_v2`
- Dashboard filter mode: `-NoDashboardFilters` until Metabase field metadata sync is reliable.

## Current Publish State

- Data preparation: complete
- SQL refresh: complete
- Local Metabase app: running
- Public dashboard route: reachable
- Dashboard builder refresh: complete in code
- Hosted Supabase upload: complete under `social_media_marketing_v2`
- Hosted Metabase collection upload: complete under Collection ID `8`
- Dashboard API reseed: complete with `-NoDashboardFilters`
- Live dashboard: `https://data.youngllilo.works/dashboard/11-social-media-marketing-performance`

## Remaining Publish Risks

- Hosted Supabase credentials are not stored in this workspace.
- Hosted Metabase admin credentials are not stored in this workspace.
- Local dashboard card reseeding needs a valid Metabase admin login.
- Public sharing and embedding decisions still need to be confirmed in hosted Metabase settings.

## Unresolved Questions

- None.
