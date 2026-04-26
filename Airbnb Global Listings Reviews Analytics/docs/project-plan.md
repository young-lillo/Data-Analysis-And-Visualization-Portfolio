# Project Plan

## Confirmed Decisions

- Framework: CRISP-DM
- Goal tier: Advanced
- Visualization tool: Metabase
- Deploy target: VPS
- Data backend: Supabase Postgres
- Infrastructure status: Metabase is already hosted on the user's VPS; Supabase credentials are available but must not be stored in repo docs or committed files.
- Price normalization: normalize listing prices to USD for cross-city comparisons.
- Exchange-rate method: use fixed 2020 annual-average FX rates, the latest complete calendar year covered by the review-date window.
- Sentiment scope: no separate review-comments file is available, so sentiment analysis is out of scope unless a text source is added later.
- Canonical cities: Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, Hong Kong.

## Intake Summary

- Project: Airbnb Global Listings & Reviews Analytics Challenge
- Dataset folder: `D:\VScode\Test\Data set\Bai 16_ Travel & Hospitality` (display-normalized; source folder name includes Vietnamese accent)
- Source files: `Listings.csv`, `Listings_data_dictionary.csv`, `Reviews.csv`, `Reviews_data_dictionary.csv`
- Business frame: hospitality analytics for market competition, USD-normalized price drivers, seasonality, COVID recovery, and value-for-money.
- Dashboard audience: portfolio reviewers and BI stakeholders who need credible, SQL-backed, decision-ready analysis.

## Dataset Surface

### Listings

- Grain: one row per Airbnb listing.
- Key fields: listing, host, host trust, response and acceptance rates, neighbourhood, district, city, latitude, longitude, property type, room type, accommodates, bedrooms, amenities, price, stay limits, review score dimensions, instant bookable.
- Analytical use: market landscape, geospatial density, price analysis, host trust segmentation, value-for-money scoring.

### Reviews

- Grain: one row per review event.
- Key fields found: `listing_id`, `review_id`, `date`, `reviewer_id`.
- Analytical use: historical demand proxy, seasonality, tourism pulse, COVID disruption and recovery.
- Limitation: no review text is available, so true text sentiment analysis is out of scope. Guest satisfaction should be measured through listing review score fields instead.
- Review date range found: 2008-11-16 to 2021-03-01.

## Clarified Problem Statement

Build an interactive Metabase dashboard over Supabase-hosted transformed tables that explains how Airbnb markets differ across 10 global cities, what features appear to influence USD-normalized price, how tourism activity changed over time, and where travelers receive the best price-quality balance.

## CRISP-DM Plan

### 1. Business Understanding

- Challenge 1: compare city competition by listing density, room type mix, and price distribution.
- Challenge 2: decode price drivers using correlation and segment analysis.
- Challenge 3: map tourism pulse from review dates, including COVID-era collapse and recovery.
- Challenge 4: define a value-for-money index combining review quality and relative affordability.

### 2. Data Understanding

- Profile row counts, nulls, duplicates, city coverage, date range, score coverage, and price outliers.
- Use the 10 canonical cities found in `Listings.csv`: Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, Hong Kong.
- Check whether prices are numeric only or include currency symbols.
- Confirm whether all prices are local currency without currency code, then map each city to its source currency.
- Define fixed 2020 annual-average USD exchange rates by source currency.
- Validate review-date coverage by city and listing.

### 3. Data Preparation

- Load raw CSVs into Supabase staging tables:
  - `stg_listings`
  - `stg_reviews`
- Build cleaned warehouse tables/views:
  - `dim_city`
  - `dim_currency_rate`
  - `dim_listing`
  - `dim_host`
  - `fact_review_activity`
  - `mart_city_market_landscape`
  - `mart_price_drivers`
  - `mart_monthly_tourism_pulse`
  - `mart_value_for_money`
- Use SQL for large aggregations over reviews.
- Use Python for amenities parsing, feature flags, correlation prep, and value index validation.
- Normalize price to USD before cross-city market, price-driver, and value comparisons.
- Map city currencies as: Paris/Rome EUR, New York USD, Sydney AUD, Rio de Janeiro BRL, Istanbul TRY, Mexico City MXN, Bangkok THB, Cape Town ZAR, Hong Kong HKD.
- Use Supabase indexes on `listing_id`, `city`, `date`, and monthly review buckets.

### 4. Modeling And Analysis

- Market landscape:
  - listing count by city, room type, property type, neighbourhood, and host status
  - median and percentile USD price bands by city and room type
  - map-ready listing density by GPS or neighbourhood
- Price formula:
  - correlations between USD-normalized price and accommodates, bedrooms, room type, property type, superhost, instant bookable, review scores, amenities, and city
  - compare superhost price premium within city and room type to avoid misleading global averages
  - rank driver strength using interpretable regression or grouped effect sizes
- Seasonality and trends:
  - monthly review count by city
  - year-over-year review recovery index
  - COVID impact windows: pre-2020 baseline, 2020 shock, 2021-2022 recovery, latest normal
  - identify peak months and stagnant periods by city
- Value-for-money:
  - USD price percentile plus review quality score
  - candidate metric: `value_index = normalized_review_score * 0.6 + affordability_score * 0.4`
  - affordability score should use USD-normalized price, with optional city-relative sensitivity checks
  - rank cities and segments, not just individual listings

### 5. Evaluation

- Check dashboard conclusions against data-quality warnings.
- Confirm cross-city price comparisons use USD-normalized prices and clearly document the 2020 annual-average exchange-rate assumption.
- Validate that review counts are framed as demand/activity proxy, not booking counts.
- Compare superhost effects within comparable segments before stating price premium.
- Test dashboard filters for city, room type, host status, time period, and price band.

### 6. Deployment

- Supabase stores staging, modeled, and mart tables.
- Metabase is already hosted on the user's VPS and connects to Supabase Postgres.
- Credentials are user-held runtime configuration and must not be written to docs, scripts, commits, or screenshots.
- Dashboard cards use SQL questions against marts, not raw 5M+ review rows.
- Exports and screenshots stay under this project docs tree.

## Metabase Dashboard Blueprint

### Page 1: Global Market Overview

- KPI cards: listings, active cities, median USD price, review records, average rating.
- Bar chart: listings by city.
- Stacked bar: room type mix by city.
- Box/violin alternative: USD price distribution by city and room type.
- Map: listing density using latitude and longitude.

### Page 2: Price Formula

- Correlation heatmap/table: USD price vs numeric drivers.
- Driver ranking: city-adjusted factors associated with higher price.
- Superhost premium chart: median price difference by city and room type.
- Amenity flags: top amenities linked with higher price.

### Page 3: Tourism Pulse

- Monthly review trend by city.
- Seasonality heatmap: city by month.
- COVID recovery index: monthly reviews versus 2019 baseline.
- Peak/stagnation callouts.

### Page 4: Value For Money

- City ranking by value index.
- Scatter: median USD price vs review score, sized by listing count.
- Segment table: best room type/city combinations for travelers.
- Map/table drilldown for high-value neighbourhoods.

## SQL And Python Depth

- SQL is primary for ingestion validation, joins, city/month aggregations, USD price marts, and Metabase marts.
- Python is used for amenities parsing, correlation analysis, optional regression, and export checks.
- Avoid running dashboard cards directly over raw reviews; pre-aggregate to monthly facts first.

## Success Criteria

- Supabase has clean staging and mart tables for Listings and Reviews.
- Cross-city pricing uses documented USD-normalized fields.
- Metabase dashboard answers all four challenges with filters and drilldowns.
- Large review history is aggregated enough for responsive dashboard queries.
- Value-for-money metric is documented, reproducible, and transparent.
- Limitations around unavailable text sentiment and exchange-rate assumptions are visible in the project docs.

## Next Workflows

1. Run `$dv-cook` to execute the full build from this plan.
2. Run `$dv-data-preparation` if you want ingestion and modeling first.
3. Run `$dv-data-visualize` after Supabase marts are ready.
4. Run `$dv-publish` after dashboard screenshots and documentation are complete.

## Risks And Mitigations

- Currency risk: listing prices are described as local-country currency. Mitigate with documented 2020 annual-average USD exchange rates and retain local-price fields for audit.
- Sentiment risk: no review-comments file is available. Mitigate by replacing text sentiment with review-score satisfaction proxies.
- Performance risk: 5M+ reviews can slow BI queries. Mitigate with monthly aggregated facts and indexes.
- Causality risk: correlation does not prove price causation. Mitigate with careful wording and within-segment comparisons.
- Geospatial risk: raw GPS maps can overplot. Mitigate with city/neighbourhood aggregation or density layers.

## Resolved Decisions

- No separate review-comments file is available; text sentiment analysis is out of scope.
- Price should be normalized to USD for cross-city comparisons.
- USD normalization uses fixed 2020 annual-average exchange rates.
- Canonical cities are Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, and Hong Kong.
- Metabase is already hosted on the user's VPS.
- Supabase credentials are available, but must stay outside repo files.

## Open Questions

- None.
