# Social Media Performance Analytics Challenge - Project Plan

## Confirmed Decisions

- Framework: `CRISP-DM`
- Goal Tier: `Advanced`
- Visualization Tool: `Metabase`
- Deploy Target: `VPS`
- Database: `Supabase`
- Dashboard Scope: full workbook by default; `scope_segment` remains in the data model but is not exposed as a dashboard filter
- Geography Grain: include `country` and `region` in the model; dashboard filtering uses `country`
- Paid Indicator: derive `promotion_type` from `Content_Type` where `Organic = organic` and `Sponsored = paid/promoted`

## User Context

You are acting as a Data Analyst for a global IT company. The project uses the Onyx 2024 social media dataset to evaluate content campaign performance across social platforms, regions, formats, hashtags, and promotion types.

Primary objective:

Use evidence from engagement, views, impressions, clicks, CTR, timing, geography, and paid status to refine content strategy and regional marketing decisions.

Portfolio angle:

This should read as an advanced stakeholder analytics case, not only a metric dashboard. The final story should explain what works, where it works, when it works, and what the marketing team should change next.

## Dataset Description

Briefed dataset surface:

- Platforms: `TikTok`, `Instagram`, `LinkedIn`, `X (Twitter)`
- Post formats: `Video`, `Carousel`, `Text`
- Content categories: `Product Promotion`, `Educational`, `Entertainment`
- Metadata: timestamp, hashtags, country, region
- Performance metrics: engagement, views, impressions, clicks, CTR
- Promotion lens: organic versus promoted or paid content

Resolved field interpretation:

- Include `country` and `region` in the model.
- Expose `country` as the dashboard geography filter per stakeholder feedback.
- Keep `region` for analytical views and regional charts, but do not expose it in the dashboard filter bar.
- Derive `promotion_type` from `Content_Type`.
- Treat `Content_Type = Organic` as organic content.
- Treat `Content_Type = Sponsored` as paid or promoted content.

Current project asset:

- Source workbook: `docs/assets/user-files/social-media-content-performance-dataset.xlsx`
- Existing prepared exports: `docs/assets/exports/`
- Existing analytical stack: Supabase-compatible PostgreSQL model plus Metabase dashboard builder

Known observed surface from the existing preparation pass:

- Rows: `5,600`
- Date range: `2024-01-01` to `2025-05-01`
- Platforms observed: `Facebook`, `Instagram`, `LinkedIn`, `TikTok`, `X.com`, `YouTube`
- Regions observed: `8`
- Main hashtags observed: `18`
- Missing click and CTR fields: `3,740` rows
- Duplicate source `post_id`: `600`

Important interpretation:

The new brief frames the project as a June 2024 Onyx challenge with four platforms. The current workbook and prepared outputs appear broader. Use this resolved scope rule:

- Keep the full workbook as the primary dashboard dataset.
- Retain `is_challenge_scope` and `scope_segment` for reconciliation, QA, and optional SQL exploration.
- Do not expose `Scope` in the Metabase filter bar because the current dashboard is intended to answer the full workbook by default.
- Document any material difference between full-dataset findings and challenge-scope findings when recommendations depend on scope.

Dashboard default: full workbook. Challenge scope remains available in the data model, not as a prominent dashboard filter.

## Problem Interpretation

The business does not only need to know which platform has the largest numbers. It needs an operating guide for future content planning.

Primary business question:

Which combination of platform, post format, content category, posting time, region, hashtag, and promotion type creates the strongest engagement, visibility, and click outcomes?

Decision areas:

1. Platform allocation
2. Content format mix
3. Regional content localization
4. Posting calendar optimization
5. Hashtag strategy
6. Video and live-stream investment
7. Paid versus organic budget decisions

## Goal Ladder

Basic:

- Profile data quality and summarize KPIs by platform, format, and region.
- Produce descriptive dashboard views.

Pro:

- Compare drivers across platform, format, category, hashtag, timing, region, and promotion type.
- Segment results by business decision area.

Advanced:

- Add scope reconciliation, statistical correlation checks, regional comparison, timing optimization, paid-versus-organic tradeoff analysis, and executive recommendations.
- Explain caveats around missing CTR, platform comparability, and non-causal interpretation.

Chosen level: `Advanced`

## CRISP-DM Framework

Chosen framework: `CRISP-DM`

Why this fits:

- The work is insight-first and stakeholder-facing.
- The main value is translating social performance data into marketing strategy.
- Supabase and Metabase are delivery tools, but the project should be judged by clarity of business understanding, analytical evidence, and recommendations.

CRISP-DM flow:

1. Business understanding
   Define marketing decisions, KPI definitions, audience needs, and scope.
2. Data understanding
   Profile platform coverage, date scope, geography, post types, hashtags, and metric availability.
3. Data preparation
   Clean timestamps, normalize categories, derive time features, handle missing CTR, and build Supabase-ready tables.
4. Modeling and analysis
   Build aggregations, scope views, correlation checks, and segment comparisons.
5. Evaluation
   Validate whether findings answer the nine analytical questions without overstating causality.
6. Deployment
   Publish Metabase dashboards on the existing VPS, connected to Supabase.

## Analytical Objectives

### Performance: Platform And Format

Question:

Which platforms and post types generate the highest engagement or views?

Required analysis:

- Rank platforms by engagement, views, impressions, and efficiency metrics.
- Compare post formats within each platform.
- Separate volume leadership from efficiency leadership.

### Strategy: Content Categories By Region

Question:

Which content categories perform best in specific geographical regions?

Required analysis:

- Region by content category matrix.
- Region by platform by category drill-down.
- Identify categories that consistently overperform in each region.

### Metrics: Optimization

Question:

How do performance metrics fluctuate based on platform, format, or hashtag usage?

Required analysis:

- Platform, format, and hashtag performance distribution.
- Engagement, impressions, clicks, CTR, and view-efficiency comparison.
- Flag metric volatility and outliers.

### Timing: Engagement

Question:

What are the optimal days and times for posting to maximize interaction?

Required analysis:

- Day-of-week and hour-of-day heatmaps.
- Platform-specific timing comparison.
- Time bucket recommendations with caveats about timezone.

### Regional: Conversion

Question:

Is there a significant regional difference in engagement and CTR?

Required analysis:

- Region-level engagement rate and CTR comparison.
- Trackable-row-only CTR analysis.
- Statistical significance check or practical-difference ranking.

### Growth: Visibility

Question:

Which hashtags are most effective for increasing impressions and clicks?

Required analysis:

- Hashtag leaderboard by impressions, clicks, CTR, and engagement.
- Minimum post threshold to avoid overrating tiny samples.
- Region and platform slices for top hashtags.

### Content: Media Trends

Question:

Which regions consistently show high video views or interest in live streams?

Required analysis:

- Video views by region and platform.
- Live-stream views by region where present.
- Compare video and non-video engagement patterns.

### Correlation: Drivers

Question:

Is there a correlation between engagement levels and content categories or posting times?

Required analysis:

- Correlation among engagement, impressions, views, clicks, CTR, posting hour, and derived features.
- Categorical driver comparison using grouped averages, medians, and indexed lift.
- Avoid causal language unless the dataset supports it.

### Comparison: Organic Versus Paid

Question:

How do organic reach and performance compare to promoted or paid content?

Required analysis:

- Organic versus paid or sponsored reach, engagement, clicks, CTR, and efficiency.
- Platform-level paid versus organic comparison.
- Recommendation on when promotion seems to improve reach versus when organic content performs efficiently.

## KPI Contract

Primary KPIs:

- Total Engagement
- Total Views
- Total Impressions
- Total Clicks
- Average Engagement Rate
- Average CTR
- Reach Efficiency = `engagement / impressions`
- Click Efficiency = `clicks / impressions`
- View Efficiency = `views / impressions`
- Clicks Per 1K Impressions = `clicks / impressions * 1000`
- Engagement Lift = segment engagement rate versus overall baseline

Guardrails:

- Treat missing clicks and CTR as unavailable, not zero.
- Run CTR analysis only on click-trackable rows.
- Use both absolute volume and normalized efficiency.
- Require minimum sample sizes for hashtag and region claims.
- Do not compare platform-native engagement rates as exact apples-to-apples unless source definitions are confirmed.

## Supabase Data Model

Recommended layers:

### Raw Layer

- `raw_social_media_posts`
  Close copy of the workbook or source extract, preserving original fields.

### Staging Layer

- `stg_social_media_posts`
  Standardized field names, typed metrics, parsed timestamps, normalized platform names, normalized categories, and row-level validation flags.

### Scope Layer

- `vw_challenge_scope_posts`
  Filterable portfolio scope for June 2024 and the four briefed platforms.

- `vw_full_dataset_posts`
  Default full workbook scope for broader exploration and validation.

### Mart Layer

- `dim_platform`
- `dim_region`
- `dim_content`
- `dim_hashtag`
- `fct_social_post_performance`
- `mart_platform_format_performance`
- `mart_region_content_performance`
- `mart_posting_time_performance`
- `mart_hashtag_performance`
- `mart_video_live_region_performance`
- `mart_organic_paid_comparison`
- `mart_correlation_inputs`

Recommended derived fields:

- `published_date`
- `published_day_of_week`
- `published_hour`
- `published_hour_bucket`
- `published_month`
- `is_challenge_scope`
- `country`
- `is_click_trackable`
- `is_video_post`
- `is_live_stream_post`
- `promotion_type`, derived from `Content_Type`
- `reach_efficiency`
- `click_efficiency`
- `view_efficiency`
- `engagement_lift_index`

## Metabase Dashboard Plan

Chosen tool: `Metabase`

Why it fits:

- You already have Metabase deployed on a VPS.
- Supabase can serve clean SQL tables and views.
- Stakeholders can use filters, saved questions, drill-downs, and public sharing.

Recommended dashboard sections:

1. Executive Overview
   Six scalar KPI cards for posts, engagement, views, impressions, average engagement rate, and average CTR, plus top findings and caveats.
2. Platform And Format Performance
   Platform leaderboard, post type comparison, and views-versus-engagement chart.
3. Regional Content Strategy
   Region and country category performance charts with lift-versus-baseline interpretation.
4. Metric Optimization
   Platform, format, and hashtag metric fluctuation charts with outlier callouts.
5. Posting Time Optimization
   Day and hour engagement views with platform and other global filters.
6. Hashtag Growth Analysis
   Impressions, clicks, CTR, and engagement by hashtag.
7. Video And Live-Stream Trends
   Regional video and live-stream interest.
8. Correlation And Driver View
   Scatterplots, correlation summary table, grouped driver lift table, and a plain-English explanation card under `Correlation Summary`.
9. Organic Versus Paid
   Reach, engagement, click, and efficiency comparison by promotion type.
10. Strategic Recommendations
   Actionable content calendar and regional strategy guidance.

Core filters:

- Date range
- Platform
- Country
- Content category
- Post type
- Promotion type
- Hashtag

Chart-selection rule:

- Use the provided `chart.md` guide for visual forms.
- Use scalar cards for executive KPIs.
- Use bar charts for ranked category, platform, hashtag, regional, and paid-versus-organic comparisons.
- Use scatter charts for two-metric relationships such as CTR versus engagement or impressions versus clicks.
- Use line charts for ordered time patterns where the x-axis has a natural sequence.
- Keep `Correlation Summary` as a compact table because it is diagnostic; add explanatory text underneath so viewers understand score direction, strength, row count, and non-causal interpretation.

## Expected SQL And Python Depth

SQL depth: `medium to high`

- Typed staging views
- Scope-specific views
- Reusable KPI definitions
- Segment marts
- Correlation input marts
- Metabase-facing saved questions or SQL cards

Python depth: `medium`

- Workbook ingestion and profiling
- Timestamp and category validation
- Optional correlation calculations
- Optional statistical comparison outputs
- Export generation for reproducibility

Advanced analysis does not require a heavy ML model. The right emphasis is rigorous segmentation, trustworthy KPIs, light statistics, and clear recommendations.

## Data Cleaning Plan

Required checks:

- Timestamp parse success and timezone assumptions
- Date filter for June 2024 challenge scope
- Platform normalization, especially `X`, `X.com`, and `Twitter`
- Post type normalization against `Video`, `Carousel`, and `Text`
- Content category normalization against brief categories
- Hashtag casing, missing values, and single versus multiple hashtag representation
- Country and region completeness
- Duplicate post identifiers
- Missing clicks and CTR
- Engagement consistency with likes, comments, and shares if those fields exist
- Organic versus paid or sponsored normalization from `Content_Type`

Cleaning outputs:

- Data quality summary
- Field dictionary
- Scope reconciliation note
- KPI null-handling rules

## EDA Plan

Produce aggregate analysis for:

- Platform and post format performance
- Regional engagement and CTR differences
- Content category performance by region
- Hashtag visibility and click effectiveness
- Posting day and posting hour patterns
- Video and live-stream regional trends
- Organic versus paid performance differences

Recommended chart patterns:

- Leaderboards for platform, hashtag, and category performance
- Heatmaps for region by category and day by hour
- Scatterplots for engagement, impressions, clicks, and CTR
- Small multiples by platform for timing or format effects
- Boxplots or distribution summaries if Metabase charting supports them cleanly

## Correlation And Driver Analysis

Use correlation carefully:

- Numeric correlations: engagement, views, impressions, clicks, CTR, posting hour, video views.
- Categorical drivers: compare medians, means, lift indexes, and sample sizes by platform, category, format, region, and promotion type.
- Timing drivers: compare engagement lift by day and hour bucket.

Expected outputs:

- Correlation-ready mart or export
- Driver summary table
- Top positive and negative lift segments
- Plain-English caveat that correlation does not prove causation

## Strategic Insight Plan

The final recommendations should answer:

- Which platforms deserve more publishing effort?
- Which formats deserve more production investment?
- Which content categories should be localized by region?
- Which days and times should be prioritized?
- Which hashtags should be reused, retired, or tested further?
- Where should video or live-stream content be emphasized?
- When does paid promotion appear worthwhile?
- Which findings require more data before acting?

Recommendation format:

- Finding
- Evidence
- Business implication
- Recommended action
- Risk or caveat

## Validation Criteria

The revised project is successful when:

- The plan records all confirmed decisions at the top.
- The brief and plan reflect the new Onyx June 2024 challenge.
- The project explicitly reconciles brief scope versus observed workbook scope.
- Supabase remains the database target.
- Metabase on VPS remains the dashboard target.
- All nine analytical questions map to concrete tables, charts, or analysis steps.
- Missing CTR and click coverage are handled safely.
- Final recommendations are actionable and caveated.

## Suggested Next Workflows

1. `$dv-data-visualize`
   Use for future dashboard refinements, card additions, or visual QA after stakeholder feedback.
2. `$dv-publish`
   Update the hosted Metabase and Supabase handoff notes after final validation or when moving from local to VPS.
3. `$dv-document-management`
   Keep `project-plan.md`, `data-preparation.md`, `visualization.md`, and publish notes synchronized when dashboard behavior changes.

## Immediate Next Step

Current implementation status:

- Data preparation has already added `country`, derived macro `region`, `is_challenge_scope`, `scope_segment`, and `promotion_type`.
- Metabase currently uses 7 global filters: date range, platform, country, content category, post type, promotion type, and hashtag.
- `Scope` and `Region` are intentionally not exposed in the dashboard filter bar.
- The dashboard has been rebuilt as a 28-card workbook with scalar KPI cards, chart-based analytical sections, a correlation explanation card, and strategic recommendations.

Next practical step:

- Validate the hosted VPS dashboard after any reseed or credential-based refresh, then update `publish.md` with the final public access notes.

## Risks

- The current workbook appears broader than the four-platform June 2024 brief.
- CTR and click data are incomplete, so conversion analysis may be sample-biased.
- Country-level segmentation depends on the country field being present and populated in the source.
- Paid versus organic assumes `Content_Type` values map cleanly to `Organic` and `Sponsored`.
- Hashtag analysis may be limited if only one main hashtag is available per post.
- Posting-time analysis needs a documented timezone assumption.

## Assumptions

- Each row represents one published post or aggregated post record.
- Supabase will be the hosted analytical database.
- Metabase is already deployed on the user's VPS.
- The dashboard should be English-language and portfolio-ready.
- The final report should include recommendations, not only charts.
- Full workbook is the default dashboard scope.
- Challenge scope remains available through `scope_segment` and `is_challenge_scope` in the data model, but is not a dashboard filter.
- `Content_Type` is the paid-status source field.

## Unresolved Questions

- None.
