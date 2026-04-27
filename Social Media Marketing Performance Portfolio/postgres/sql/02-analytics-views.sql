create or replace view vw_sm_platform_overview as
select
  scope_segment,
  platform,
  count(*) as posts,
  sum(engagement) as total_engagement,
  sum(views) as total_views,
  sum(impressions) as total_impressions,
  sum(clicks) as total_clicks,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr
from fact_social_post_performance
group by 1, 2;

create or replace view vw_sm_platform_post_type_performance as
select * from mart_platform_performance;

create or replace view vw_sm_region_category_performance as
select * from mart_region_content_performance;

create or replace view vw_sm_posting_hour_performance as
select * from mart_posting_time_performance;

create or replace view vw_sm_posting_day_performance as
select
  scope_segment,
  platform,
  published_day_of_week,
  published_day_sort,
  sum(posts) as posts,
  round(avg(avg_engagement), 2) as avg_engagement,
  round(avg(avg_views), 2) as avg_views,
  round(avg(avg_engagement_rate), 4) as avg_engagement_rate,
  round(avg(avg_ctr), 4) as avg_ctr
from mart_posting_time_performance
group by 1, 2, 3, 4;

create or replace view vw_sm_hashtag_effectiveness as
select
  scope_segment,
  main_hashtag,
  platform,
  region,
  country,
  sum(posts) as posts,
  sum(total_impressions) as total_impressions,
  sum(total_clicks) as total_clicks,
  round(avg(avg_ctr), 4) as avg_ctr,
  round(avg(avg_engagement_rate), 4) as avg_engagement_rate
from mart_hashtag_performance
group by 1, 2, 3, 4, 5;

create or replace view vw_sm_video_live_region_interest as
select * from mart_video_live_region_performance;

create or replace view vw_sm_organic_vs_sponsored as
select * from mart_content_type_comparison;

create or replace view vw_sm_regional_ctr_comparison as
select
  scope_segment,
  region,
  country,
  platform,
  count(*) filter (where is_click_trackable) as trackable_posts,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  sum(clicks) as total_clicks,
  sum(impressions) as total_impressions
from fact_social_post_performance
group by 1, 2, 3, 4;

create or replace view vw_sm_correlation_driver_inputs as
select * from mart_correlation_inputs;

create or replace view vw_sm_post_detail as
select
  post_row_id,
  post_id,
  source_platform,
  platform,
  region,
  country,
  scope_segment,
  is_challenge_scope,
  content_type,
  promotion_type,
  content_category,
  post_type,
  main_hashtag,
  post_date,
  is_click_trackable,
  published_day_of_week,
  post_hour,
  engagement,
  views,
  impressions,
  clicks,
  click_through_rate,
  engagement_rate,
  video_views,
  live_stream_views
from fact_social_post_performance;

create or replace view vw_sm_executive_overview as
select
  scope_segment,
  count(*) as posts,
  min(post_date) as first_post_date,
  max(post_date) as last_post_date,
  sum(engagement) as total_engagement,
  sum(views) as total_views,
  sum(impressions) as total_impressions,
  sum(clicks) as total_clicks,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr,
  count(*) filter (where is_click_trackable) as trackable_posts,
  round(count(*) filter (where is_click_trackable)::numeric / nullif(count(*), 0), 4) as trackable_post_share
from fact_social_post_performance
group by 1;

create or replace view vw_sm_platform_format_efficiency as
select
  scope_segment,
  platform,
  post_type,
  promotion_type,
  count(*) as posts,
  sum(engagement) as total_engagement,
  sum(views) as total_views,
  sum(impressions) as total_impressions,
  sum(clicks) as total_clicks,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr,
  round(sum(engagement) / nullif(sum(impressions), 0), 4) as reach_efficiency,
  round(sum(clicks) / nullif(sum(impressions), 0), 4) as click_efficiency,
  round(sum(views) / nullif(sum(impressions), 0), 4) as view_efficiency
from fact_social_post_performance
group by 1, 2, 3, 4;

create or replace view vw_sm_region_category_lift as
with baseline as (
  select scope_segment, avg(engagement_rate) as baseline_engagement_rate
  from fact_social_post_performance
  group by 1
)
select
  f.scope_segment,
  f.region,
  f.country,
  f.content_category,
  f.platform,
  count(*) as posts,
  round(avg(f.engagement_rate), 4) as avg_engagement_rate,
  round(avg(f.engagement_rate) - b.baseline_engagement_rate, 4) as engagement_rate_lift,
  round(avg(f.click_through_rate) filter (where f.is_click_trackable), 4) as avg_ctr
from fact_social_post_performance f
join baseline b on b.scope_segment = f.scope_segment
group by 1, 2, 3, 4, 5, b.baseline_engagement_rate;

create or replace view vw_sm_metric_outlier_posts as
select
  post_row_id,
  scope_segment,
  post_date,
  platform,
  region,
  country,
  content_category,
  post_type,
  promotion_type,
  main_hashtag,
  engagement,
  views,
  impressions,
  clicks,
  round(engagement_rate, 4) as engagement_rate,
  round(click_through_rate, 4) as ctr,
  round(view_efficiency, 4) as view_efficiency
from fact_social_post_performance
where impressions > 0;

create or replace view vw_sm_posting_time_heatmap as
select
  scope_segment,
  platform,
  published_day_of_week,
  published_day_sort,
  post_hour,
  count(*) as posts,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr
from fact_social_post_performance
group by 1, 2, 3, 4, 5;

create or replace view vw_sm_hashtag_growth_leaderboard as
select
  scope_segment,
  main_hashtag,
  platform,
  region,
  country,
  count(*) as posts,
  sum(impressions) as total_impressions,
  sum(clicks) as total_clicks,
  sum(engagement) as total_engagement,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round((sum(clicks) / nullif(sum(impressions), 0)) * 1000, 2) as clicks_per_1k_impressions
from fact_social_post_performance
where main_hashtag is not null
group by 1, 2, 3, 4, 5;

create or replace view vw_sm_video_vs_non_video_performance as
select
  scope_segment,
  region,
  country,
  platform,
  case when is_video_post then 'Video' else 'Non-video' end as media_group,
  count(*) as posts,
  round(avg(views), 2) as avg_views,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr
from fact_social_post_performance
group by 1, 2, 3, 4, 5;

create or replace view vw_sm_numeric_correlation_summary as
select scope_segment, 'views vs engagement' as relationship, round(corr(views, engagement)::numeric, 4) as correlation, count(*) as rows_used
from fact_social_post_performance group by 1
union all
select scope_segment, 'impressions vs engagement', round(corr(impressions, engagement)::numeric, 4), count(*)
from fact_social_post_performance group by 1
union all
select scope_segment, 'clicks vs engagement', round(corr(clicks, engagement)::numeric, 4), count(clicks)
from fact_social_post_performance where clicks is not null group by 1
union all
select scope_segment, 'CTR vs engagement rate', round(corr(click_through_rate, engagement_rate)::numeric, 4), count(click_through_rate)
from fact_social_post_performance where click_through_rate is not null group by 1
union all
select scope_segment, 'posting hour vs engagement rate', round(corr(post_hour, engagement_rate)::numeric, 4), count(*)
from fact_social_post_performance group by 1
union all
select scope_segment, 'video views vs engagement', round(corr(video_views, engagement)::numeric, 4), count(*)
from fact_social_post_performance group by 1;

create or replace view vw_sm_driver_lift_summary as
with baseline as (
  select scope_segment, avg(engagement_rate) as base_rate
  from fact_social_post_performance
  group by 1
),
drivers as (
  select scope_segment, 'platform' as driver_type, platform as driver_value, count(*) as posts, avg(engagement_rate) as avg_engagement_rate
  from fact_social_post_performance group by 1, 2, 3
  union all
  select scope_segment, 'content_category', content_category, count(*), avg(engagement_rate)
  from fact_social_post_performance group by 1, 2, 3
  union all
  select scope_segment, 'post_type', post_type, count(*), avg(engagement_rate)
  from fact_social_post_performance group by 1, 2, 3
  union all
  select scope_segment, 'promotion_type', promotion_type, count(*), avg(engagement_rate)
  from fact_social_post_performance group by 1, 2, 3
  union all
  select scope_segment, 'posting_day', published_day_of_week, count(*), avg(engagement_rate)
  from fact_social_post_performance group by 1, 2, 3
)
select
  d.scope_segment,
  d.driver_type,
  d.driver_value,
  d.posts,
  round(d.avg_engagement_rate, 4) as avg_engagement_rate,
  round(d.avg_engagement_rate - b.base_rate, 4) as engagement_rate_lift
from drivers d
join baseline b on b.scope_segment = d.scope_segment;

create or replace view vw_sm_organic_paid_performance as
select
  scope_segment,
  promotion_type,
  platform,
  count(*) as posts,
  sum(impressions) as total_impressions,
  sum(views) as total_views,
  sum(engagement) as total_engagement,
  sum(clicks) as total_clicks,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr,
  round(sum(engagement) / nullif(sum(impressions), 0), 4) as reach_efficiency,
  round(sum(clicks) / nullif(sum(impressions), 0), 4) as click_efficiency
from fact_social_post_performance
group by 1, 2, 3;
