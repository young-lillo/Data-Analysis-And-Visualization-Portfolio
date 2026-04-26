# Social Media Marketing Performance Portfolio - Project Plan

## Confirmed Decisions

- Framework: `CRISP-DM`
- Goal Tier: `Advanced`
- Visualization Tool: `Metabase`
- Deploy Target: `VPS`

## User Context

You want an English-language portfolio project built from the provided Onyx social media workbook.

Stack direction already chosen:

- `Supabase` for storage, SQL modeling, and prepared analytical tables
- `Metabase` on your existing VPS for stakeholder-facing dashboards

Primary business intent:

Identify what makes content successful across platforms, explain regional engagement behavior, and support better content and channel strategy decisions.

## Dataset Surface

Source file:

- User-provided workbook: `Social_Media_Content_Performance_Dataset.xlsx`

Observed workbook structure:

- 1 worksheet
- 5,600 rows
- 24 columns
- Date span: `2024-01-01` to `2025-05-01`

Observed columns:

- `Post_ID`
- `Platform`
- `Content_Type`
- `Content_Category`
- `Post_Type`
- `Region`
- `Longitude`
- `Latitude`
- `Engagement`
- `Views`
- `Likes`
- `Shares`
- `Comments`
- `Engagement_Rate`
- `Impressions`
- `Video_Views`
- `Live_Stream_Views`
- `Clicks`
- `Click_Through_Rate`
- `Main_Hashtag`
- `Post_Published_At`
- `Post_Date`
- `Post_Hour`
- `Engagement_Level`

Observed analytical surface:

- Platforms present in the file: `Facebook`, `Instagram`, `LinkedIn`, `TikTok`, `X.com`, `YouTube`
- Content types: `Organic`, `Sponsored`
- Content categories: `Customer Story`, `Educational`, `Entertainment`, `Event / Webinar`, `Product Promotion`
- Post types: `Article`, `Carousel`, `Image`, `Live Stream`, `PDF`, `Text`, `Video`
- Regions: 8
- Main hashtags: 18
- Rows with non-zero `Video_Views`: 2,948
- Rows with non-zero `Live_Stream_Views`: 924
- Missing `Clicks`: 3,740 rows
- Missing `Click_Through_Rate`: 3,740 rows

Important interpretation:

Your brief mentions four platforms, but the actual file contains six. The project should use the real dataset surface and explicitly note that platform coverage extends beyond the original summary.

## Problem Interpretation

This is not only a dashboard about vanity metrics. The stronger portfolio angle is content performance intelligence across platform, format, timing, region, and promotion type.

Core business question:

How should a marketing team decide what content to publish, where to publish it, when to publish it, and whether to promote it, based on cross-platform evidence from engagement, reach, views, and CTR?

Decision areas the project should support:

1. Platform allocation
2. Content mix selection
3. Posting-time optimization
4. Regional strategy adaptation
5. Hashtag usage strategy
6. Organic versus sponsored investment decisions

## Chosen Goal Ladder

- Basic: descriptive KPI dashboard by platform, content type, and region
- Pro: driver analysis by post format, category, hashtag, region, and posting hour
- Advanced: strategic recommendation layer with timing patterns, regional segmentation, organic versus sponsored tradeoffs, and portfolio-style decision guidance

Chosen level: `Advanced`

Implication:

The final output should go beyond descriptive charts. It should include explainable strategic takeaways, reusable KPI definitions, and a clear decision story for marketers.

## Framework Recommendation

Chosen framework: `CRISP-DM`

Why it fits:

- The project is insight-first, not pipeline-first
- The portfolio value comes from converting marketing questions into analytical evidence and recommendations
- Supabase and Metabase provide the technical layer, but the center of gravity is still business understanding and evaluation

Planned CRISP-DM flow:

1. Business understanding
   Define success metrics, business questions, and strategic decisions.
2. Data understanding
   Validate platform coverage, regional coverage, time range, and KPI sparsity.
3. Data preparation
   Clean types, normalize metrics, derive time features, and prepare dashboard-ready tables in Supabase.
4. Modeling
   Build analytical marts for content, platform, region, timing, hashtag, and paid-versus-organic comparisons.
5. Evaluation
   Confirm the outputs answer the stated questions without overstating causal claims.
6. Deployment
   Publish an interactive Metabase dashboard on the existing VPS-backed environment.

## Recommended Visualization Path

Chosen tool: `Metabase`

Why it fits:

- You already have a Metabase host
- The dataset is relational and metric-heavy, which fits SQL-first BI well
- The project needs stakeholder-friendly dashboards, filterable exploration, and reusable questions
- Supabase can serve as the clean analytical backend for Metabase with low operational friction

Role of Supabase in this project:

- land the raw Excel dataset
- store cleaned analytical tables
- expose SQL views or materialized tables for Metabase
- keep transformation logic reproducible and shareable

## Recommended Data Model

Use a layered model in Supabase.

### Raw Layer

- `raw_social_media_posts`
  Close copy of the Excel file with typed ingest metadata

### Clean Layer

- `stg_social_media_posts`
  Standardized names, typed metrics, parsed timestamps, cleaned nulls, normalized text categories

### Mart Layer

- `dim_platform`
  Platform name and grouped channel metadata
- `dim_region`
  Region, longitude, latitude
- `dim_content`
  Content category, post type, content type
- `dim_hashtag`
  Main hashtag
- `fct_social_post_performance`
  One post per row with all cleaned KPIs
- `mart_platform_performance`
  Aggregated platform and post-type metrics
- `mart_region_content_performance`
  Region by category and format performance
- `mart_posting_time_performance`
  Day, hour, platform, and category timing summaries
- `mart_hashtag_performance`
  Hashtag effectiveness by impressions, clicks, CTR, and engagement
- `mart_content_type_comparison`
  Organic versus sponsored performance summaries

Recommended derived fields:

- `published_day_of_week`
- `published_month`
- `published_hour_bucket`
- `engagement_per_impression`
- `clicks_per_1k_impressions`
- `views_per_post`
- `video_view_share`
- `live_stream_view_share`
- `is_click_trackable`
- `is_video_post`
- `is_live_stream_post`

## KPI Contract

Use explicit KPI definitions in the project so Metabase questions remain consistent.

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

Guardrails:

- Only calculate CTR-based comparisons where click tracking exists
- Treat missing `Clicks` and `Click_Through_Rate` as unavailable, not zero, unless a source rule proves otherwise
- Separate volume metrics from efficiency metrics so large platforms do not dominate every chart

## Analytical Deliverables

The dashboard should answer these questions:

1. Which platforms and post types generate the highest engagement, views, and impressions?
2. Which content categories perform best by region?
3. How do engagement, reach, and CTR vary by platform, post format, and hashtag?
4. What days and hours are most effective for posting?
5. Are there meaningful regional differences in engagement rate and CTR?
6. Which hashtags consistently improve impressions or clicks?
7. Which regions show strong video consumption or stronger live-stream interest?
8. What relationships appear between engagement and content category or posting time?
9. How do organic and sponsored posts differ in reach, efficiency, and click performance?

Recommended dashboard sections:

- Executive Overview
- Platform and Format Performance
- Content Category and Regional Insights
- Posting Time Optimization
- Hashtag Effectiveness
- Video and Live Stream Performance
- Organic vs Sponsored Comparison
- Strategic Recommendations

## Expected SQL And Python Depth

SQL depth: `medium`

- ingestion validation
- typed staging transformations
- reusable views for KPI logic
- aggregation by platform, region, category, hashtag, and posting time

Python depth: `low to medium`

- Excel ingestion
- optional profiling and validation
- optional export helpers if you want repeatable load scripts

This project does not require advanced ML to deliver strong value. The analytical weight should stay on reliable BI modeling and careful metric interpretation.

## Metabase Delivery Direction

Recommended build sequence in Metabase:

1. Create a clean Supabase connection dedicated to this project
2. Expose staging tables only for internal validation
3. Build dashboard-facing questions from mart tables or curated SQL models
4. Add global filters for platform, region, content category, content type, post type, date range, and hashtag
5. Add one executive dashboard plus one drill-down dashboard for regional and timing analysis

Recommended core Metabase questions:

1. Platform leaderboard by engagement and views
2. Post-type performance by platform
3. Regional category heatmap
4. Posting-hour performance matrix
5. Top hashtags by impressions, clicks, and CTR
6. Organic versus sponsored comparison
7. Video versus live-stream regional demand
8. Correlation-ready scatter comparing impressions, engagement, and clicks

## Data Quality And Validation Focus

Validate these items early in `$dv-data-preparation`:

- true platform list versus stakeholder summary
- timestamp parsing consistency between `Post_Published_At`, `Post_Date`, and `Post_Hour`
- duplicate `Post_ID` rows
- null handling for `Clicks` and `Click_Through_Rate`
- whether `Engagement` aligns with `Likes + Shares + Comments` or is independently sourced
- whether `Views`, `Video_Views`, and `Live_Stream_Views` overlap or should be interpreted separately
- region naming consistency
- hashtag formatting consistency such as casing and punctuation

Critical caveats:

- The dataset appears post-level, not campaign-level, so attribution claims should stay modest
- CTR coverage is incomplete, so regional or platform CTR findings may be sample-biased
- Latitude and longitude likely represent region centroids, not exact audience locations

## Risks

- The business brief names four platforms, but the live data contains six, which can create expectation mismatch
- Missing click metrics on many rows can distort paid-versus-organic or hashtag conclusions if not handled carefully
- Engagement rate may not be directly comparable across all platforms if the source calculation logic differs
- Time optimization findings can drift if timezone assumptions are not documented
- Hashtag analysis may be limited because only one `Main_Hashtag` field is present, not a full hashtag list

## Assumptions

- Each row represents one published post
- `Content_Type` is the organic versus sponsored flag
- `Main_Hashtag` is the dominant hashtag intended for analysis
- `Post_Hour` reflects the posting hour in the source system's business timezone
- Metabase will consume prepared Supabase tables, not the raw Excel directly

## Success Criteria

- The Excel file is reproducibly loaded into Supabase
- Cleaned tables and marts exist for platform, region, timing, hashtag, and paid-versus-organic analysis
- KPI definitions are documented and consistently implemented
- The final Metabase dashboard answers all nine core business questions
- The dashboard produces actionable English-language recommendations, not only charts
- The project is portfolio-ready for demo or stakeholder walkthrough

## Suggested Next Workflows

1. `$dv-data-preparation`
   Build the Supabase ingest path, typed staging layer, KPI logic, and mart tables.
2. `$dv-data-visualize`
   Build Metabase questions, filters, dashboard layout, and narrative flow.
3. `$dv-publish`
   Prepare handoff notes, deployment checklist, and sharing setup for the VPS-hosted dashboard.

## Implementation Direction For The Next Step

The next owner workflow should produce:

- a reproducible Excel-to-Supabase load path
- a field dictionary for all staging and mart tables
- a KPI definition sheet with null-handling rules
- SQL models for the final Metabase questions
- a shortlist of the final dashboard cards and filters

## Unresolved Questions

- Should the portfolio story focus on one brand or remain platform-agnostic as a benchmark analysis?
- Do you want recommendation text written directly into the dashboard, or only in project docs?
- Do you want the final output to include a public case-study page in addition to the Metabase dashboard?
