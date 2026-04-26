drop schema if exists public cascade;
create schema public;

create table dim_platform (
  platform text primary key,
  channel_group text
);

create table dim_region (
  region text primary key,
  longitude numeric(12, 6),
  latitude numeric(12, 6)
);

create table dim_content (
  content_key text primary key,
  content_type text not null,
  content_category text not null,
  post_type text not null
);

create table dim_hashtag (
  main_hashtag text primary key
);

create table fact_social_post_performance (
  post_row_id text primary key,
  source_row_number integer not null,
  post_id text not null,
  platform text references dim_platform (platform),
  region text references dim_region (region),
  content_key text references dim_content (content_key),
  main_hashtag text references dim_hashtag (main_hashtag),
  post_published_at timestamp,
  post_date date,
  published_day_of_week text,
  published_day_sort integer,
  published_month text,
  post_hour integer,
  published_hour_bucket text,
  engagement_level text,
  content_type text,
  content_category text,
  post_type text,
  engagement numeric(18, 4),
  views numeric(18, 4),
  likes numeric(18, 4),
  shares numeric(18, 4),
  comments numeric(18, 4),
  engagement_rate numeric(18, 8),
  impressions numeric(18, 4),
  video_views numeric(18, 4),
  live_stream_views numeric(18, 4),
  clicks numeric(18, 4),
  click_through_rate numeric(18, 8),
  reach_efficiency numeric(18, 8),
  click_efficiency numeric(18, 8),
  view_efficiency numeric(18, 8),
  video_view_share numeric(18, 8),
  live_stream_view_share numeric(18, 8),
  is_click_trackable boolean,
  is_video_post boolean,
  is_live_stream_post boolean,
  longitude numeric(12, 6),
  latitude numeric(12, 6)
);

create table mart_platform_performance (
  platform text,
  post_type text,
  content_type text,
  posts integer,
  total_engagement numeric(18, 4),
  total_views numeric(18, 4),
  total_impressions numeric(18, 4),
  total_clicks numeric(18, 4),
  avg_engagement_rate numeric(18, 8),
  avg_ctr numeric(18, 8)
);

create table mart_region_content_performance (
  region text,
  content_category text,
  platform text,
  posts integer,
  total_engagement numeric(18, 4),
  total_impressions numeric(18, 4),
  total_clicks numeric(18, 4),
  avg_engagement_rate numeric(18, 8),
  avg_ctr numeric(18, 8)
);

create table mart_posting_time_performance (
  platform text,
  published_day_of_week text,
  published_day_sort integer,
  post_hour integer,
  posts integer,
  avg_engagement numeric(18, 8),
  avg_views numeric(18, 8),
  avg_engagement_rate numeric(18, 8),
  avg_ctr numeric(18, 8)
);

create table mart_hashtag_performance (
  main_hashtag text,
  platform text,
  posts integer,
  total_impressions numeric(18, 4),
  total_clicks numeric(18, 4),
  avg_ctr numeric(18, 8),
  avg_engagement_rate numeric(18, 8)
);

create table mart_content_type_comparison (
  content_type text,
  platform text,
  posts integer,
  total_impressions numeric(18, 4),
  total_views numeric(18, 4),
  total_clicks numeric(18, 4),
  avg_engagement_rate numeric(18, 8),
  avg_ctr numeric(18, 8)
);

create table mart_video_live_region_performance (
  region text,
  platform text,
  posts integer,
  total_video_views numeric(18, 4),
  total_live_stream_views numeric(18, 4),
  avg_video_views numeric(18, 8),
  avg_live_stream_views numeric(18, 8)
);

copy dim_platform from '/seed/dim-platform.csv' csv header;
copy dim_region from '/seed/dim-region.csv' csv header;
copy dim_content from '/seed/dim-content.csv' csv header;
copy dim_hashtag from '/seed/dim-hashtag.csv' csv header;
copy fact_social_post_performance from '/seed/fact-social-post-performance.csv' csv header;
copy mart_platform_performance from '/seed/mart-platform-performance.csv' csv header;
copy mart_region_content_performance from '/seed/mart-region-content-performance.csv' csv header;
copy mart_posting_time_performance from '/seed/mart-posting-time-performance.csv' csv header;
copy mart_hashtag_performance from '/seed/mart-hashtag-performance.csv' csv header;
copy mart_content_type_comparison from '/seed/mart-content-type-comparison.csv' csv header;
copy mart_video_live_region_performance from '/seed/mart-video-live-region-performance.csv' csv header;

create index idx_sm_fact_platform_date on fact_social_post_performance (platform, post_date, post_hour);
create index idx_sm_fact_region_category on fact_social_post_performance (region, content_category, post_type);
create index idx_sm_fact_trackable on fact_social_post_performance (is_click_trackable, content_type, platform);
