create or replace view vw_sm_platform_overview as
select
  platform,
  count(*) as posts,
  sum(engagement) as total_engagement,
  sum(views) as total_views,
  sum(impressions) as total_impressions,
  sum(clicks) as total_clicks,
  round(avg(engagement_rate), 4) as avg_engagement_rate,
  round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr
from fact_social_post_performance
group by 1;

create or replace view vw_sm_platform_post_type_performance as
select * from mart_platform_performance;

create or replace view vw_sm_region_category_performance as
select * from mart_region_content_performance;

create or replace view vw_sm_posting_hour_performance as
select * from mart_posting_time_performance;

create or replace view vw_sm_posting_day_performance as
select
  platform,
  published_day_of_week,
  published_day_sort,
  sum(posts) as posts,
  round(avg(avg_engagement), 2) as avg_engagement,
  round(avg(avg_views), 2) as avg_views,
  round(avg(avg_engagement_rate), 4) as avg_engagement_rate,
  round(avg(avg_ctr), 4) as avg_ctr
from mart_posting_time_performance
group by 1, 2, 3;

create or replace view vw_sm_hashtag_effectiveness as
select
  main_hashtag,
  sum(posts) as posts,
  sum(total_impressions) as total_impressions,
  sum(total_clicks) as total_clicks,
  round(avg(avg_ctr), 4) as avg_ctr,
  round(avg(avg_engagement_rate), 4) as avg_engagement_rate
from mart_hashtag_performance
group by 1;

create or replace view vw_sm_video_live_region_interest as
select * from mart_video_live_region_performance;

create or replace view vw_sm_organic_vs_sponsored as
select * from mart_content_type_comparison;

create or replace view vw_sm_post_detail as
select
  post_row_id,
  post_id,
  platform,
  region,
  content_type,
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
