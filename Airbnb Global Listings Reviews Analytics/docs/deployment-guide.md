# Deployment Guide

## Target Architecture

- Data warehouse: Supabase Postgres
- Schema: `airbnb`
- BI layer: Metabase on VPS
- Dashboard collection: Airbnb
- Repository policy: commit scripts, docs, screenshots, and prepared aggregate marts; keep raw source CSVs and credentials out of git

## Supabase Setup

1. Open the SQL editor in Supabase.
2. Run `docs/assets/exports/03-local-metabase-load.sql`.
3. Import each prepared CSV mart from `docs/assets/exports/` into its matching table.
4. Validate key row counts:

```sql
select count(*) from airbnb.mart_city_market_landscape;
select count(*) from airbnb.mart_room_type_mix;
select count(*) from airbnb.mart_listing_density_map;
select count(*) from airbnb.mart_monthly_tourism_pulse;
```

Expected counts:

- `mart_city_market_landscape`: 10
- `mart_room_type_mix`: 40
- `mart_listing_density_map`: 5377
- `mart_monthly_tourism_pulse`: 1292

## Metabase Setup

1. Connect Metabase to Supabase using Metabase admin settings.
2. Sync database schema.
3. Confirm Metabase can see the `airbnb` schema.
4. Create or open the target Airbnb collection.
5. Run:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://YOUR_METABASE_HOST" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID
```

To update an existing dashboard:

```powershell
.\tools\create-metabase-dashboard.ps1 `
  -BaseUrl "https://YOUR_METABASE_HOST" `
  -Username "YOUR_METABASE_EMAIL" `
  -Password "YOUR_METABASE_PASSWORD" `
  -DatabaseId YOUR_DATABASE_ID `
  -CollectionId YOUR_COLLECTION_ID `
  -DashboardId YOUR_DASHBOARD_ID
```

## Security Checklist

- Do not commit `.env` files.
- Do not commit Supabase URLs, passwords, service-role keys, or Metabase admin credentials.
- Do not publish screenshots that show admin database settings or connection strings.
- Use environment/admin configuration for credentials instead of repository files.

## Unresolved Questions

- None.
