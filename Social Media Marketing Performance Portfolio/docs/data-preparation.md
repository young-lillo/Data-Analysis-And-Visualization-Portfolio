# Data Preparation

## Goal

Prepare a trusted analytics surface for the Social Media Marketing Performance portfolio and make it directly usable by Supabase-compatible PostgreSQL and Metabase.

## Inputs

- Source workbook: `docs/assets/user-files/social-media-content-performance-dataset.xlsx`
- Source sheet count: `1`
- Project contract: `docs/project-plan.md`

## Executed Steps

1. Copied the user workbook into the project docs tree for local reproducibility.
2. Built reproducible exports with [build-social-media-prepared-exports.py](../tools/build-social-media-prepared-exports.py).
3. Standardized source column names into a SQL-friendly shape.
4. Added a stable `post_row_id` because `post_id` is not unique in the file.
5. Parsed numeric, date, and timestamp fields.
6. Derived time attributes including day of week, month, and hour buckets.
7. Derived KPI helpers such as `reach_efficiency`, `click_efficiency`, `view_efficiency`, and trackable-click flags.
8. Built dimension and mart exports for platform, region, content, hashtag, posting-time, and paid-versus-organic analysis.

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
- `data-preparation-summary.json`

## Validation Summary

From `data-preparation-summary.json`:

- Source rows: `5,600`
- Duplicate `post_id`: `600`
- Platforms: `6`
- Regions: `8`
- Hashtags: `18`
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
  One row per `platform x post_type x content_type`.
- `mart-region-content-performance.csv`
  One row per `region x content_category x platform`.
- `mart-posting-time-performance.csv`
  One row per `platform x day_of_week x hour`.
- `mart-hashtag-performance.csv`
  One row per `hashtag x platform`.

## Derived Business Logic

- `post_row_id`
  Stable row-level primary key because `post_id` repeats.
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

- `post_id` is not unique, so row-level analysis must use `post_row_id`.
- Click and CTR coverage is partial and concentrated in a subset of platforms.
- `engagement` is not equal to `likes + shares + comments`, so it should be treated as a source-provided aggregate metric.
- The file contains `Facebook` and `YouTube` in addition to the four platforms described in the project brief.
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
- `vw_sm_post_detail`
