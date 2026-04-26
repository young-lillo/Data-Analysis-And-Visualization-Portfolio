# Publish

## Status

- Workflow: `$dv-cook` publish handoff
- Status: local Metabase dashboard rebuilt from `project-plan.md` blueprint and validated; ready to mirror into VPS Metabase/Supabase
- Deploy target: user's VPS-hosted Metabase
- Data backend: Supabase Postgres

## Ready Assets

- Supabase model contract: `docs/assets/exports/01-analysis.sql`
- Metabase question pack: `docs/assets/exports/02-metabase-questions.sql`
- Local Metabase mart loader: `docs/assets/exports/03-local-metabase-load.sql`
- Extra blueprint mart generator: `docs/assets/exports/04-blueprint-marts.py`
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

Known hosted IDs:

- Metabase base URL: `https://data.youngllilo.works`
- Collection ID: `6`
- Database ID: `2`

Create a new hosted dashboard:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://data.youngllilo.works" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId 2 `
  -CollectionId 6
```

Update an existing hosted dashboard in place:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://data.youngllilo.works" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId 2 `
  -CollectionId 6 `
  -DashboardId YOUR_DASHBOARD_ID
```

## Security Notes

- Do not commit Supabase credentials.
- Do not place Metabase connection strings in docs.
- Do not publish screenshots showing secrets, hostnames, tokens, or admin panels.

## Validation Status

- Data profiling script: passed
- Python compile check: passed
- Kit unit tests: passed, 54/54
- Local Metabase check: passed at `http://localhost:3001`
- Dashboard URL: `http://localhost:3001/dashboard/2-airbnb-global-listings-reviews-analytics`
- Dashboard cards: 21/21 executed successfully
- Dashboard tabs/pages: 4/4 created and validated
- Visual correction QA: Page 1 pin map and stacked bar validated; Page 2 heatmap tables and superhost median-price-difference view validated; Page 3 seasonality heatmap and monthly reviews vs 2019 baseline validated.
- Dashboard filters: City and Room Type static-list dropdown/multi-select filters added and validated against mapped cards.

## Unresolved Questions

- None.
