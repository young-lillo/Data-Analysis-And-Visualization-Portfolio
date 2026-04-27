# Project Brief

## Project

Social Media Performance Analytics Challenge (June 2024)

## Role

Act as a Data Analyst for a global IT company evaluating social media content performance across regions and platforms.

## Business Context

The company wants to refine content strategy and regional marketing decisions using the Onyx 2024 social media dataset. The analysis should identify which content, formats, timing choices, hashtags, regions, and promotion types drive stronger interaction, visibility, and conversion outcomes.

## Dataset

Source: Onyx 2024 Dataset

Expected brief surface:

- Platforms: `TikTok`, `Instagram`, `LinkedIn`, `X (Twitter)`
- Metadata: post type, content category, timestamp, hashtags
- Metrics: engagement, views, impressions, clicks, click-through rate
- Geography: country and region performance segments

Current project asset:

- `docs/assets/user-files/social-media-content-performance-dataset.xlsx`

Known validation note:

- Existing prepared outputs show broader platform and date coverage than the new brief states. Use the full workbook as the primary dashboard dataset and retain challenge-scope fields for June 2024 and the briefed platforms in the data model.

## Confirmed Decisions

- Framework: `CRISP-DM`
- Goal tier: `Advanced`
- Visualization tool: `Metabase`
- Deploy target: `VPS`
- Database: `Supabase`
- Dashboard scope: full workbook by default; challenge scope remains available in the data model, not as a dashboard filter
- Geography: include `country` and `region` in the model; expose `country` as the dashboard filter
- Paid indicator: derive `promotion_type` from `Content_Type` where `Organic = organic` and `Sponsored = paid/promoted`

## Audience

- Marketing managers
- Regional marketing leads
- Growth and content strategists
- Portfolio reviewers or hiring managers

## Core Analytical Questions

1. Which platforms and post types generate the highest engagement or views?
2. Which content categories perform best in specific geographical regions?
3. How do performance metrics fluctuate by platform, format, or hashtag usage?
4. What are the optimal days and times for posting to maximize interaction?
5. Is there a significant regional difference in engagement and CTR?
6. Which hashtags are most effective for increasing impressions and clicks?
7. Which regions consistently show high video views or live-stream interest?
8. Is engagement correlated with content categories or posting times?
9. How do organic reach and performance compare to promoted or paid content?

## Execution Strategy

1. Data cleaning: validate timestamps, categorical fields, missing metrics, and geography.
2. EDA: aggregate platform, format, region, content category, hashtag, and timing patterns.
3. Correlation analysis: test relationships among engagement, content category, posting time, platform, and paid status.
4. Strategic insights: produce actionable recommendations for content planning, regional targeting, and promotion strategy.

## Deliverables

- Revised CRISP-DM project plan
- Supabase-ready preparation contract
- Metabase dashboard specification
- KPI definitions and caveats
- Strategic recommendation structure for the final report
