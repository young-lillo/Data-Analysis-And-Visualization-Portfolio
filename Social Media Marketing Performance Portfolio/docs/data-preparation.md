# Data Preparation

## Goal

Prepare a trusted analytics surface for the Social Media Performance Analytics Challenge and make it directly usable by Supabase-compatible PostgreSQL and Metabase.

## Inputs

- Source workbook: `docs/assets/user-files/social-media-content-performance-dataset.xlsx`
- Source sheet count: `1`
- Confirmed dashboard scope: full workbook by default; challenge scope remains available in the data model, not as a dashboard filter

## Executed Steps

1. Rebuilt prepared exports with [build-social-media-prepared-exports.py](../tools/build-social-media-prepared-exports.py).
2. Standardized source columns into a SQL-friendly shape.
3. Added stable `post_row_id` because `post_id` is not unique.
4. Normalized `X.com`, `X`, and `Twitter` to `X (Twitter)`.
5. Derived `country` from the source `Region` field because no `Country` column exists in the workbook.
6. Derived macro `region` from country: `North America`, `Latin America`, `Europe`, and `APAC`.
7. Derived `promotion_type` from `Content_Type`.
8. Added `is_challenge_scope` for June 2024 plus TikTok, Instagram, LinkedIn, and X (Twitter).
9. Added `scope_segment` so analysts can distinguish `Challenge Scope` versus `Full Workbook Only` in SQL exploration and QA.
10. Parsed timestamp, date, numeric, and metric fields.
11. Derived time features, KPI helpers, video flags, and click-trackability flags.
12. Built dimensions, fact table, mart exports, and correlation-ready inputs.

## Prepared Outputs

Location: `docs/assets/exports/`

- `dim-platform.csv`
- `dim-region.csv`
- `dim-content.csv`
- `dim-hashtag.csv`
- `fact-social-post-performance.csv`
- `mart-platform-performance.csv`
- `mart-region-content-performance.csv`
- `mart-posting-time-performance.csv`
- `mart-hashtag-performance.csv`
- `mart-content-type-comparison.csv`
- `mart-video-live-region-performance.csv`
- `mart-correlation-inputs.csv`
- `data-preparation-summary.json`

## Validation Summary

From `data-preparation-summary.json`:

- Source rows: `5,600`
- Challenge-scope rows: `246`
- Full-workbook-only rows: `5,354`
- Duplicate `post_id`: `600`
- Source platforms: `Facebook`, `Instagram`, `LinkedIn`, `TikTok`, `X.com`, `YouTube`
- Normalized platforms: `Facebook`, `Instagram`, `LinkedIn`, `TikTok`, `X (Twitter)`, `YouTube`
- Countries: `Australia`, `Brazil`, `Canada`, `Germany`, `India`, `Japan`, `UK`, `USA`
- Derived regions: `APAC`, `Europe`, `Latin America`, `North America`
- Country source: `Derived from Region column`
- Promotion types: `Organic`, `Paid/Promoted`
- Date range: `2024-01-01` to `2025-05-01`
- Missing `Clicks`: `3,740`
- Missing `Click Through Rate`: `3,740`
- Click-trackable rows: `1,860`
- Rows with non-zero `video_views`: `2,948`
- Rows with non-zero `live_stream_views`: `924`
- Rows where `engagement != likes + shares + comments`: `5,600`

## Trusted Grain

- `fact-social-post-performance.csv`
  One source row per published post record.
- `mart-platform-performance.csv`
  One row per `scope_segment x platform x post_type x promotion_type`.
- `mart-region-content-performance.csv`
  One row per `scope_segment x region x country x content_category x platform`.
- `mart-posting-time-performance.csv`
  One row per `scope_segment x platform x day_of_week x hour`.
- `mart-hashtag-performance.csv`
  One row per `scope_segment x hashtag x platform x region x country`.
- `mart-content-type-comparison.csv`
  One row per `scope_segment x promotion_type x source_content_type x platform`.
- `mart-video-live-region-performance.csv`
  One row per `scope_segment x region x country x platform`.
- `mart-correlation-inputs.csv`
  One row per post with driver and metric fields for correlation and lift analysis.

## Derived Business Logic

- `post_row_id`
  Stable row-level primary key because `post_id` repeats.
- `country`
  Derived from source `Region` because the workbook does not include a separate country field.
- `region`
  Derived macro region from `country`.
- `promotion_type`
  `Organic` stays `Organic`; `Sponsored` becomes `Paid/Promoted`.
- `is_challenge_scope`
  True when `post_date` is in June 2024 and platform is TikTok, Instagram, LinkedIn, or X (Twitter).
- `scope_segment`
  `Challenge Scope` when `is_challenge_scope` is true; otherwise `Full Workbook Only`.
- `is_click_trackable`
  True when `clicks` or `click_through_rate` is available.
- `is_video_post`
  True when `video_views > 0` or `post_type = 'Video'`.
- `is_live_stream_post`
  True when `live_stream_views > 0` or `post_type = 'Live Stream'`.
- `reach_efficiency = engagement / impressions`
- `click_efficiency = clicks / impressions`
- `view_efficiency = views / impressions`

## Data Risks

- The source has no separate `Country` column; country is inferred from the source `Region` values.
- The current workbook is broader than the June 2024 four-platform challenge scope.
- `post_id` is not unique, so row-level analysis must use `post_row_id`.
- Click and CTR coverage is partial, so conversion charts must use trackable rows carefully.
- `engagement` is not equal to `likes + shares + comments`, so treat it as a source-provided aggregate.
- Only one `main_hashtag` is available per row, so hashtag analysis is simplified.

## Hand-off Contract For Visualization

Metabase should treat the following as canonical sources:

- `vw_sm_platform_overview`
- `vw_sm_platform_post_type_performance`
- `vw_sm_region_category_performance`
- `vw_sm_posting_hour_performance`
- `vw_sm_posting_day_performance`
- `vw_sm_hashtag_effectiveness`
- `vw_sm_video_live_region_interest`
- `vw_sm_organic_vs_sponsored`
- `vw_sm_regional_ctr_comparison`
- `vw_sm_correlation_driver_inputs`
- `vw_sm_post_detail`

## Unresolved Questions

- None.
