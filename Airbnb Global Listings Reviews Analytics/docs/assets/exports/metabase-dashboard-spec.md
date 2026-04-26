# Metabase Dashboard Spec

## Collection

- Collection: `Airbnb Global Listings & Reviews`
- Dashboard: `Airbnb Global Listings & Reviews Analytics`
- Local URL: `http://localhost:3001/dashboard/2-airbnb-global-listings-reviews-analytics`
- Database: local Postgres mart database for development; Supabase Postgres for VPS deployment
- Schema: `airbnb`
- Credential rule: configure Supabase connection in Metabase admin UI or environment variables only.

## Dashboard Tabs

### Page 1: Global Market Overview

Blueprint requirements:
- KPI cards: listings, active cities, median USD price, review records, average rating
- Bar chart: listings by city
- Stacked bar: room type mix by city
- Box/violin alternative: USD price distribution by city and room type
- Map: listing density using latitude and longitude

Local cards:
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

Blueprint requirements:
- Correlation heatmap/table: USD price vs numeric drivers
- Driver ranking: city-adjusted factors associated with higher price
- Superhost premium heatmap: median USD price difference by city and room type
- Amenity flags: top amenities linked with higher price

Local cards:
- `Blueprint - Correlation Heatmap Table`
- `Blueprint - Driver Ranking`
- `Blueprint - Superhost Median Price Difference Heatmap`
- `Blueprint - Amenity Price Premium Flags`

### Page 3: Tourism Pulse

Blueprint requirements:
- Monthly review trend by city
- Seasonality heatmap: city by month
- COVID recovery index: monthly reviews versus 2019 baseline
- Peak/stagnation callouts

Local cards:
- `Blueprint - Monthly Review Trend by City`
- `Blueprint - Seasonality Heatmap City by Month`
- `Blueprint - Monthly Reviews vs 2019 Baseline`
- `Blueprint - Peak and Stagnation Callouts`

### Page 4: Value For Money

Blueprint requirements:
- City ranking by value index
- Scatter: median USD price vs review score, sized by listing count
- Segment table: best room type/city combinations for travelers
- Map/table drilldown for high-value neighbourhoods

Local cards:
- `Blueprint - City Ranking by Value Index`
- `Blueprint - Median USD Price vs Review Score Scatter`
- `Blueprint - Best City Room Segments for Travelers`
- `Blueprint - High Value Neighbourhood Drilldown`

## Dashboard Filters

- City
- Room Type
- City and Room Type are static-list dropdown, multi-select dashboard filters.
- City is mapped to all cards whose marts expose a city dimension.
- Room Type is mapped to cards whose marts expose a room type dimension.
- Correlation, driver ranking, and amenity premium summaries are intentionally global and remain unfiltered.

Native SQL cards use Metabase Field Filter variables:
- `{{city}}`
- `{{room_type}}`

## Validation Checklist

- Four tabs/pages exist.
- Twenty-one blueprint cards exist.
- Every card query executes successfully.
- Corrected cards render as a pin map, stacked bar, heatmap-style tables, and monthly reviews versus 2019 baseline line chart.
- City and Room Type static-list dropdown/multi-select filters are wired and validated.
- Cards run against prepared marts or modeled views, not raw review scans.
- Cross-city prices show USD-normalized values only.
- Text sentiment is not claimed because no review text source exists.
- Public screenshots do not show Supabase hostnames, tokens, passwords, or connection strings.
