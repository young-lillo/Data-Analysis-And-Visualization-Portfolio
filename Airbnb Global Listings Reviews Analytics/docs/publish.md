# Publish

## Status

- Status: dashboard assets validated for local or hosted Metabase reproduction
- Deploy target: VPS-hosted Metabase
- Data backend: Supabase Postgres

## Ready Assets

- Supabase model contract: `docs/assets/exports/01-analysis.sql`
- Metabase question pack: `docs/assets/exports/02-metabase-questions.sql`
- Local Metabase mart loader: `docs/assets/exports/03-local-metabase-load.sql`
- Extra dashboard mart generator: `docs/assets/exports/04-blueprint-marts.py`
- Dashboard spec: `docs/assets/exports/metabase-dashboard-spec.md`
- Hosted Metabase dashboard builder: `tools/create-metabase-dashboard.ps1`
- Local mart exports and analysis summary under `docs/assets/exports/`

## Publish Checklist

1. Apply `01-analysis.sql` in Supabase.
2. Load `Listings.csv` into `airbnb.stg_listings`.
3. Load `Reviews.csv` into `airbnb.stg_reviews`.
4. Confirm indexes exist on city, listing ID, and review date.
5. Connect Metabase to Supabase using environment/admin config, not repository files.
6. Create/update the hosted Metabase dashboard with `tools/create-metabase-dashboard.ps1`.
7. If building manually, create Metabase native SQL questions from `02-metabase-questions.sql`.
8. If building manually, assemble dashboard pages from `metabase-dashboard-spec.md`.
9. Capture screenshots under `docs/assets/screenshots/` after sensitive connection details are hidden.

## Hosted Metabase Upload

Use your own hosted Metabase URL, database ID, and collection ID.

Create a new hosted dashboard:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://YOUR_METABASE_HOST" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID
```

Update an existing hosted dashboard in place:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://YOUR_METABASE_HOST" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID `
  -DashboardId YOUR_DASHBOARD_ID
```

## Security Notes

- Do not commit Supabase credentials.
- Do not place Metabase connection strings in docs.
- Do not publish screenshots showing secrets, hostnames, tokens, or admin panels.

## Validation Checklist

- Data profiling script runs successfully.
- Metabase can query the `airbnb` schema.
- Dashboard cards execute without SQL errors.
- Dashboard pages and filters load for public viewers.
- Screenshots do not expose credentials or admin settings.

## Unresolved Questions

- None.
