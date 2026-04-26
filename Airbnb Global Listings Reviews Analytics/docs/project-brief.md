# Project Brief

## Identity

- Slug: market-landscape-price-drivers-seasonality-and-covid-recover
- Project: Airbnb Global Listings & Reviews Analytics Challenge
- Dataset folder: `D:\VScode\Test\Data set\Bai 16_ Travel & Hospitality` (display-normalized; source folder name includes Vietnamese accent)
- Framework: CRISP-DM
- Goal tier: Advanced
- Visualization tool: Metabase
- Deploy target: VPS
- Data backend: Supabase Postgres
- Infrastructure status: Metabase already hosted on user's VPS; Supabase credentials available but must stay outside repo files.
- Price normalization: USD
- Exchange-rate method: fixed 2020 annual-average FX rates
- Sentiment scope: no review-comments file available, so text sentiment is out of scope.
- Canonical cities: Paris, New York, Sydney, Rome, Rio de Janeiro, Istanbul, Mexico City, Bangkok, Cape Town, Hong Kong

## Goals

- Compare market landscape and competition across global Airbnb cities.
- Decode USD-normalized price drivers, including whether Superhost status correlates with higher prices.
- Use review history as a tourism activity pulse for seasonality and COVID recovery.
- Build a transparent value-for-money index for traveler recommendations.
- Use listing review score fields as guest satisfaction proxies instead of text sentiment.

## Open Questions

- None.

## Intake Contract

- Mandatory decision gate was completed with the user.
- `docs/project-plan.md` is the canonical plan for downstream `$dv-*` workflows.
- Continue through `$dv-cook`, `$dv-data-preparation`, `$dv-data-visualize`, or `$dv-publish`.
