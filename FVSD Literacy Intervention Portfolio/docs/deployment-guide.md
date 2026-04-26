# Full Deployment Guide

## Purpose

This guide records the deployment shape for the FVSD Literacy Intervention Portfolio so the project can be re-deployed, audited, or handed off without guessing.

## Current Architecture

```text
Source workbook
  -> prepared CSV exports
  -> PostgreSQL analytics database
  -> Metabase dashboard
  -> public website
```

Current project runtime pieces:

- PostgreSQL analytics database seeded from `docs/assets/exports/`
- Metabase for dashboard delivery
- PowerShell dashboard builder for repeatable dashboard creation and update

## Deployment Inputs

- Stack file: [docker-compose.yml](../docker-compose.yml)
- Init scripts: [postgres/init](../postgres/init)
- Schema and views: [01-schema-and-load.sql](../postgres/sql/01-schema-and-load.sql)
- Dashboard builder: [create-metabase-dashboard.ps1](../tools/create-metabase-dashboard.ps1)
- Prepared exports: [docs/assets/exports](assets/exports)

## Reproducible Local Stack

Start local services:

```powershell
docker compose up -d
```

Check running containers:

```powershell
docker compose ps
```

Check Postgres seed logs:

```powershell
docker compose logs postgres
```

## Rebuild or Update the Dashboard

Create a new dashboard:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "http://localhost:3000" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID
```

Update an existing dashboard in place:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://YOUR_METABASE_DOMAIN" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID `
  -DashboardId YOUR_DASHBOARD_ID
```

## Minimum Validation After Deployment

1. Confirm the website opens at the real public URL.
2. Confirm Metabase can query the FVSD analytics database.
3. Confirm the dashboard loads without broken cards.
4. Confirm key cards show expected Winter `2023 / 2024` forecast totals:
   - Tier 2 teachers: `252`
   - Tier 3 teachers: `382`
   - Forecast testing cost: `6881.10`
5. Confirm filters and section narrative still match the deployed dashboard.

## GitHub Safety Notes

- Do not commit production `.env` files.
- Do not commit reverse-proxy certificates, SSH keys, or password files.
- Development defaults in the local compose file are not production secrets, but production credentials still need to stay out of git.
- If any temporary password was used during manual setup, rotate it before a public push.

## Recommended Repository Extras

- Add one deployed dashboard screenshot to `docs/assets/screenshots/overview.png`
- Add one filtered school-level screenshot to `docs/assets/screenshots/school-detail.png`
- Keep this guide updated if the hosting path, domain, or Metabase collection changes

## Unresolved Metadata

- Public website URL not yet recorded in the repo
- Public Metabase URL not yet recorded in the repo
- Screenshot assets not yet present in `docs/assets/screenshots/`
