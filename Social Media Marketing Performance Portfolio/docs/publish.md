# Publish

## Deploy Target

- Tool path: `Metabase`
- Target: `VPS`
- Database target: `Supabase`
- Live dashboard URL: use your published Metabase dashboard URL
- Local validation URL: `http://localhost:3001`

## Deployment Assets

- Docker stack: [docker-compose.yml](../docker-compose.yml)
- Database init scripts: [01-create-databases.sh](../postgres/init/01-create-databases.sh), [02-load-social-media-analytics.sh](../postgres/init/02-load-social-media-analytics.sh)
- SQL schema and views: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql), [02-analytics-views.sql](../postgres/sql/02-analytics-views.sql)
- Prepared exports: `docs/assets/exports/`
- Dashboard builder: [create-metabase-dashboard.ps1](../tools/create-metabase-dashboard.ps1)

## Publish Checklist

- `data-preparation.md` exists and reflects the refreshed prepared-data contract.
- `visualization.md` exists and reflects the updated Metabase dashboard direction.
- `publish.md` exists.
- Prepared exports exist under `docs/assets/exports/`.
- `mart-correlation-inputs.csv` exists for driver analysis.
- PostgreSQL schema and analytics views load successfully.
- Local Metabase stack runs at `http://localhost:3001`.
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
  -BaseUrl "https://YOUR_METABASE_HOST" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID `
  -SqlSchema "social_media_marketing_v2" `
  -NoDashboardFilters
```

## Validation Checklist

- Prepared exports regenerate successfully.
- PostgreSQL schema and analytics views load successfully.
- Metabase can query the selected schema.
- Dashboard cards execute without SQL errors.
- Public sharing is enabled only after credentials and admin settings are hidden.

## Unresolved Questions

- None.
