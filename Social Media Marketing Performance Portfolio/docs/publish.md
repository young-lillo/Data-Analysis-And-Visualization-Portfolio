# Publish

## Deploy Target

- Tool path: `Metabase`
- Target: `VPS`
- Local validation URL: `http://localhost:3001`

## Deployment Assets

- Docker stack: [docker-compose.yml](../docker-compose.yml)
- Database init scripts: [01-create-databases.sh](../postgres/init/01-create-databases.sh), [02-load-social-media-analytics.sh](../postgres/init/02-load-social-media-analytics.sh)
- SQL schema and views: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql), [02-analytics-views.sql](../postgres/sql/02-analytics-views.sql)

## Publish Checklist

- `project-brief.md` exists
- `project-plan.md` exists
- `data-preparation.md` exists
- `visualization.md` exists
- `publish.md` exists
- prepared exports exist under `docs/assets/exports/`
- Dockerized local Metabase stack is available
- Local Metabase dashboard is seeded at `http://localhost:3001/dashboard/2`
- Local public share link is available at `http://localhost:3001/public/dashboard/b9f811ac-fd0a-49c3-b4b6-d4597cc04d13`
- Dashboard now includes field-backed category filters, chart guidance, and an insights/recommendations section
- `.gitignore` excludes export artifacts and local volume outputs

## Supabase Handoff

The SQL model in this project is PostgreSQL-first so it can be moved into Supabase with minimal changes.

Recommended handoff path:

1. Load `fact-social-post-performance.csv` and dimensions into Supabase
2. Recreate the analytics views from `02-analytics-views.sql`
3. Point your hosted Metabase instance at the Supabase Postgres connection
4. Re-run the dashboard builder script against the hosted Metabase instance

## Remaining Publish Risks

- Hosted Supabase credentials are not stored in this workspace
- Hosted Metabase admin credentials are not stored in this workspace
- Public sharing and embedding decisions still need to be made in Metabase settings
