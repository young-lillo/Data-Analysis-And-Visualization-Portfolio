# Data Preparation

## Status

- Workflow: `$dv-cook` data-preparation stage
- Status: complete
- Source dataset: `D:\VScode\Test\Data set\Bai 16_ Travel & Hospitality` (display-normalized; source folder name includes Vietnamese accent)
- Runtime: standard-library Python, no pandas/numpy dependency
- Credential handling: Supabase credentials were not read, written, or embedded

## Prepared Contract

### Source Grains

- `Listings.csv`: one row per listing
- `Reviews.csv`: one row per review event

### Validation Results

- Listings processed: 279,712
- Reviews processed: 5,373,143
- Unmatched review rows: 0
- Review date range: 2008-11-16 to 2021-03-01
- Canonical cities: Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, Hong Kong

### Transformation Rules

- Normalize prices to USD with fixed 2020 annual-average FX rates.
- Keep source local-price fields auditable in Supabase.
- Use listing review-score fields as guest satisfaction proxy.
- Exclude text sentiment analysis because no review-comments file exists.
- Aggregate review activity to monthly city facts before Metabase visualization.

## Generated Assets

- `docs/assets/exports/01-analysis.py`: reproducible local profiling and mart export script
- `docs/assets/exports/airbnb_analysis_config.py`: city, currency, FX, and field config
- `docs/assets/exports/airbnb_analysis_utils.py`: parsing, quantile, correlation, CSV helpers
- `docs/assets/exports/01-analysis.sql`: Supabase schema, modeled views, marts, indexes
- `docs/assets/exports/fx-rates-2020.csv`: fixed annual-average FX table
- `docs/assets/exports/data-quality-summary.json`: row counts, date range, null summary
- `docs/assets/exports/mart-city-market-landscape.csv`
- `docs/assets/exports/mart-room-type-mix.csv`
- `docs/assets/exports/mart-monthly-tourism-pulse.csv`
- `docs/assets/exports/mart-price-driver-correlations.csv`
- `docs/assets/exports/mart-amenity-price-premium.csv`
- `docs/assets/exports/mart-value-for-money-city.csv`
- `docs/assets/exports/analysis-summary.md`

## Key Findings

- Paris has the largest listing footprint: 64,690 listings.
- Rome and Paris dominate peak review activity; strongest observed months are in 2019.
- Accommodates and bedrooms are the strongest simple numeric price correlates.
- Superhost status is not positively correlated with global USD price in the unsegmented scan.
- Mexico City, Bangkok, and Istanbul lead the current value-for-money index.

## Supabase Load Notes

- Apply `01-analysis.sql` in Supabase SQL editor or via `psql`.
- Load source CSVs into `airbnb.stg_listings` and `airbnb.stg_reviews`.
- Recreate or refresh modeled views after load.
- Keep connection strings and API keys in environment variables or Metabase admin config only.

## Unresolved Questions

- None.
