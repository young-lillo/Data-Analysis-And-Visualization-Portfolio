# Visualization

## Status

- Tool: Metabase
- Status: dashboard assets and screenshots are included for GitHub review and local reproduction

## Prepared Dashboard Assets

- `docs/assets/exports/metabase-dashboard-spec.md`
- `docs/assets/exports/02-metabase-questions.sql`
- `docs/assets/exports/01-analysis.sql`
- `docs/assets/exports/03-local-metabase-load.sql`
- `docs/assets/exports/04-blueprint-marts.py`
- Prepared CSV marts in `docs/assets/exports/`

## Dashboard Implementation

### Page 1: Global Market Overview

- KPI cards: listings, active cities, median USD price, review records, average rating
- Bar chart: listings by city
- Stacked bar: room type mix by city
- Box/violin alternative: USD price distribution by city and room type
- Map: listing density using latitude and longitude

Local Metabase cards:
- `Blueprint - Total Listings KPI`
- `Blueprint - Active Cities KPI`
- `Blueprint - Median USD Price KPI`
- `Blueprint - Review Records KPI`
- `Blueprint - Average Rating KPI`
- `Blueprint - Listings by City`
- `Blueprint - Room Type Mix by City (Stacked Bar)`
- `Blueprint - USD Price Distribution by City and Room Type`
- `Blueprint - Listing Density Pin Map`

### Page 2: Price Formula

- Correlation heatmap/table: USD price vs numeric drivers
- Driver ranking: city-adjusted factors associated with higher price
- Superhost premium heatmap: median USD price difference by city and room type
- Amenity flags: top amenities linked with higher price

Local Metabase cards:
- `Blueprint - Correlation Heatmap Table`
- `Blueprint - Driver Ranking`
- `Blueprint - Superhost Median Price Difference Heatmap`
- `Blueprint - Amenity Price Premium Flags`

### Page 3: Tourism Pulse

- Monthly review trend by city
- Seasonality heatmap: city by month
- COVID recovery index: monthly reviews versus 2019 baseline
- Peak/stagnation callouts

Local Metabase cards:
- `Blueprint - Monthly Review Trend by City`
- `Blueprint - Seasonality Heatmap City by Month`
- `Blueprint - Monthly Reviews vs 2019 Baseline`
- `Blueprint - Peak and Stagnation Callouts`

### Page 4: Value For Money

- City ranking by value index
- Scatter: median USD price vs review score, sized by listing count
- Segment table: best room type/city combinations for travelers
- Map/table drilldown for high-value neighbourhoods

Local Metabase cards:
- `Blueprint - City Ranking by Value Index`
- `Blueprint - Median USD Price vs Review Score Scatter`
- `Blueprint - Best City Room Segments for Travelers`
- `Blueprint - High Value Neighbourhood Drilldown`

## Dashboard Filters

- City
- Room Type

Implemented local Metabase filters:
- `City`: static-list dropdown, multi-select, 10 values.
- `Room Type`: static-list dropdown, multi-select, 4 values.

Filter wiring:
- City is mapped to 18 dashboard cards with city-level marts.
- Room Type is mapped to 8 dashboard cards whose marts expose `room_type`.
- Global analytical summary cards without city/room dimensions remain unfiltered: correlation ranking and amenity premium summaries.

## Validation Notes

- Local dashboard health endpoint passed: `http://localhost:3001/api/health`
- Dashboard tabs/pages: 4/4 created
- Dashboard cards: 21/21 created
- Dashboard card query validation: 21/21 passed
- Page 1 correction: listing density renders as an OpenStreetMap pin map, and room type mix renders as a stacked bar.
- Page 2 correction: correlation renders as a heatmap-style table, and superhost premium renders as a city-by-room heatmap of median USD price difference.
- Page 3 correction: seasonality renders as a city-by-month heatmap-style table, and COVID recovery renders monthly review counts against 2019 baseline series.
- Dashboard filter validation: City and Room Type static-list multi-select dropdowns are visible and execute against mapped native SQL cards.
- Cards run against prepared marts, not raw 5M+ review scans.
- Cross-city prices use USD-normalized fields.
- Text sentiment is not claimed; dashboard uses guest satisfaction/review score proxy language.
- Screenshots and exports must not expose Supabase hostnames, keys, passwords, or connection strings.

## Unresolved Questions

- None.
