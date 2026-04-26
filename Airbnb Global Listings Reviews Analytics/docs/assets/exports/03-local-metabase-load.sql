create schema if not exists airbnb;

drop table if exists airbnb.mart_city_market_landscape cascade;
create table airbnb.mart_city_market_landscape (
  city text primary key,
  currency text,
  listing_count integer,
  review_count integer,
  median_price_usd numeric,
  p25_price_usd numeric,
  p75_price_usd numeric,
  avg_rating numeric
);

drop table if exists airbnb.mart_room_type_mix cascade;
create table airbnb.mart_room_type_mix (
  city text,
  room_type text,
  listing_count integer
);

drop table if exists airbnb.mart_monthly_tourism_pulse cascade;
create table airbnb.mart_monthly_tourism_pulse (
  city text,
  review_month text,
  review_count integer,
  baseline_2019_avg numeric,
  recovery_index numeric
);

drop table if exists airbnb.mart_price_driver_correlations cascade;
create table airbnb.mart_price_driver_correlations (
  driver text primary key,
  n integer,
  pearson_with_price_usd numeric
);

drop table if exists airbnb.mart_amenity_price_premium cascade;
create table airbnb.mart_amenity_price_premium (
  amenity text primary key,
  listing_count integer,
  avg_price_usd numeric,
  avg_price_premium_usd numeric
);

drop table if exists airbnb.mart_value_for_money_city cascade;
create table airbnb.mart_value_for_money_city (
  city text primary key,
  median_price_usd numeric,
  avg_rating numeric,
  affordability_score numeric,
  rating_score numeric,
  value_index numeric
);

drop table if exists airbnb.fx_rates_2020 cascade;
create table airbnb.fx_rates_2020 (
  currency text primary key,
  local_per_usd numeric,
  rate_year integer
);

drop table if exists airbnb.mart_price_distribution_city_room cascade;
create table airbnb.mart_price_distribution_city_room (
  city text,
  room_type text,
  listing_count integer,
  p25_price_usd numeric,
  median_price_usd numeric,
  p75_price_usd numeric
);

drop table if exists airbnb.mart_superhost_premium cascade;
create table airbnb.mart_superhost_premium (
  city text,
  room_type text,
  superhost_listing_count integer,
  regular_listing_count integer,
  superhost_median_usd numeric,
  regular_median_usd numeric,
  premium_usd numeric
);

drop table if exists airbnb.mart_listing_density_map cascade;
create table airbnb.mart_listing_density_map (
  city text,
  latitude numeric,
  longitude numeric,
  listing_count integer
);

drop table if exists airbnb.mart_seasonality_heatmap cascade;
create table airbnb.mart_seasonality_heatmap (
  city text,
  month_number text,
  avg_review_count numeric
);

drop table if exists airbnb.mart_tourism_peak_stagnation_callouts cascade;
create table airbnb.mart_tourism_peak_stagnation_callouts (
  city text,
  callout_type text,
  review_month text,
  review_count integer,
  recovery_index numeric
);

drop table if exists airbnb.mart_city_room_value_segments cascade;
create table airbnb.mart_city_room_value_segments (
  city text,
  room_type text,
  listing_count integer,
  median_price_usd numeric,
  avg_rating numeric,
  value_index numeric
);

drop table if exists airbnb.mart_neighbourhood_value_drilldown cascade;
create table airbnb.mart_neighbourhood_value_drilldown (
  city text,
  neighbourhood text,
  listing_count integer,
  median_price_usd numeric,
  avg_rating numeric
);
