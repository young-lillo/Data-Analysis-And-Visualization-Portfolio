# Cook Analysis Summary

## Dataset Validation

- Listings processed: 279,712
- Reviews processed: 5,373,143
- Review rows matched to listings: 5,373,143
- Unmatched review rows: 0
- Review date range: 2008-11-16 to 2021-03-01
- Canonical cities: Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, Hong Kong
- Price basis: USD-normalized with fixed 2020 annual-average FX rates
- Sentiment basis: listing review scores only; no review text file exists

## Market Landscape Signals

| City | Listings | Reviews | Median USD Price | Avg Rating |
|---|---:|---:|---:|---:|
| Paris | 64,690 | 1,213,727 | 91.22 | 93.06 |
| New York | 37,012 | 847,727 | 99.00 | 93.77 |
| Sydney | 33,630 | 482,552 | 82.64 | 93.23 |
| Rome | 27,647 | 1,113,360 | 74.12 | 93.52 |
| Rio de Janeiro | 26,615 | 323,274 | 54.28 | 94.57 |
| Istanbul | 24,519 | 194,013 | 35.95 | 91.06 |
| Mexico City | 20,065 | 477,584 | 30.76 | 94.84 |
| Bangkok | 19,361 | 284,342 | 35.15 | 93.00 |
| Cape Town | 19,086 | 302,336 | 64.95 | 94.40 |
| Hong Kong | 7,087 | 134,228 | 49.77 | 89.71 |

## Price Formula Signals

- Strongest positive numeric correlations with USD price are `accommodates` (0.167) and `bedrooms` (0.147).
- Superhost status has a weak negative overall correlation with USD price (-0.0118), so any premium claim should be made only after city and room-type segmentation.
- Higher listing price is weakly associated with location score (0.0219), but score-price correlations are generally small.
- Amenity premium scan suggests `Hot tub`, `Pool`, `Air conditioning`, and `Gym` deserve dashboard callouts.

## Tourism Pulse Signals

- Peak observed months are concentrated in 2019, especially Paris and Rome.
- Top month in the prepared mart: Paris, 2019-06, with 38,774 reviews.
- COVID impact should be shown through the 2019 baseline recovery index instead of raw monthly counts only.

## Value For Money Ranking

| Rank | City | Value Index | Median USD Price | Avg Rating |
|---:|---|---:|---:|---:|
| 1 | Mexico City | 0.9690 | 30.76 | 94.84 |
| 2 | Bangkok | 0.9323 | 35.15 | 93.00 |
| 3 | Istanbul | 0.9159 | 35.95 | 91.06 |
| 4 | Rio de Janeiro | 0.8296 | 54.28 | 94.57 |
| 5 | Hong Kong | 0.8268 | 49.77 | 89.71 |

## Dashboard-Ready Outputs

- `mart-city-market-landscape.csv`
- `mart-room-type-mix.csv`
- `mart-monthly-tourism-pulse.csv`
- `mart-price-driver-correlations.csv`
- `mart-amenity-price-premium.csv`
- `mart-value-for-money-city.csv`
- `fx-rates-2020.csv`
- `data-quality-summary.json`
- `01-analysis.sql`
- `02-metabase-questions.sql`
- `metabase-dashboard-spec.md`

## Unresolved Questions

- None.
