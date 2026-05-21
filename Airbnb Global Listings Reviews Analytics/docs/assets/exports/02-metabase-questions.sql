-- Metabase question pack aligned to the dashboard specification.
-- Use these native SQL questions after loading the airbnb marts.
-- Dashboard filters:
-- - {{city}} is a Metabase Field Filter dropdown/multi-select mapped to each mart's city field.
-- - {{room_type}} is a Metabase Field Filter dropdown/multi-select mapped to room_type where that mart supports it.

-- Page 1: Global Market Overview
select sum(listing_count) as total_listings
from airbnb.mart_room_type_mix
where 1=1 [[and {{city}}]] [[and {{room_type}}]];

select count(distinct city) as active_cities
from airbnb.mart_room_type_mix
where 1=1 [[and {{city}}]] [[and {{room_type}}]];

select round(percentile_cont(0.5) within group (order by median_price_usd)::numeric, 2) as median_city_price_usd
from airbnb.mart_price_distribution_city_room
where 1=1 [[and {{city}}]] [[and {{room_type}}]];

select sum(review_count) as review_records
from airbnb.mart_city_market_landscape
where 1=1 [[and {{city}}]];

select round(avg(avg_rating), 2) as average_rating
from airbnb.mart_city_market_landscape
where 1=1 [[and {{city}}]];

select city, sum(listing_count) as listing_count
from airbnb.mart_room_type_mix
where 1=1 [[and {{city}}]] [[and {{room_type}}]]
group by city
order by listing_count desc;

select city, room_type, listing_count
from airbnb.mart_room_type_mix
where 1=1 [[and {{city}}]] [[and {{room_type}}]]
order by city, room_type;

select city, room_type, listing_count, p25_price_usd, median_price_usd, p75_price_usd
from airbnb.mart_price_distribution_city_room
where 1=1 [[and {{city}}]] [[and {{room_type}}]]
order by city, room_type;

select city, latitude, longitude, listing_count
from airbnb.mart_listing_density_map
where 1=1 [[and {{city}}]]
order by listing_count desc
limit 2000;

-- Page 2: Price Formula
select driver, n, pearson_with_price_usd
from airbnb.mart_price_driver_correlations
order by abs(pearson_with_price_usd) desc;

select driver, abs(pearson_with_price_usd) as driver_strength
from airbnb.mart_price_driver_correlations
order by driver_strength desc;

select
  city,
  max(premium_usd) filter (where room_type = 'Entire place') as entire_place,
  max(premium_usd) filter (where room_type = 'Hotel room') as hotel_room,
  max(premium_usd) filter (where room_type = 'Private room') as private_room,
  max(premium_usd) filter (where room_type = 'Shared room') as shared_room
from airbnb.mart_superhost_premium
where premium_usd is not null [[and {{city}}]] [[and {{room_type}}]]
group by city
order by city;

select amenity, listing_count, avg_price_premium_usd
from airbnb.mart_amenity_price_premium
where avg_price_premium_usd is not null
order by avg_price_premium_usd desc;

-- Page 3: Tourism Pulse
select city, review_month, review_count
from airbnb.mart_monthly_tourism_pulse
where 1=1 [[and {{city}}]]
order by city, review_month;

select
  city,
  max(avg_review_count) filter (where month_number = '01') as jan,
  max(avg_review_count) filter (where month_number = '02') as feb,
  max(avg_review_count) filter (where month_number = '03') as mar,
  max(avg_review_count) filter (where month_number = '04') as apr,
  max(avg_review_count) filter (where month_number = '05') as may,
  max(avg_review_count) filter (where month_number = '06') as jun,
  max(avg_review_count) filter (where month_number = '07') as jul,
  max(avg_review_count) filter (where month_number = '08') as aug,
  max(avg_review_count) filter (where month_number = '09') as sep,
  max(avg_review_count) filter (where month_number = '10') as oct,
  max(avg_review_count) filter (where month_number = '11') as nov,
  max(avg_review_count) filter (where month_number = '12') as dec
from airbnb.mart_seasonality_heatmap
where 1=1 [[and {{city}}]]
group by city
order by city;

with filtered as (
  select *
  from airbnb.mart_monthly_tourism_pulse
  where review_month >= '2019-01' [[and {{city}}]]
)
select city || ' monthly reviews' as series, (review_month || '-01')::date as review_month, review_count::numeric as value
from filtered
union all
select city || ' 2019 baseline' as series, (review_month || '-01')::date as review_month, baseline_2019_avg::numeric as value
from filtered
where baseline_2019_avg is not null
order by series, review_month;

select city, callout_type, review_month, review_count, recovery_index
from airbnb.mart_tourism_peak_stagnation_callouts
where 1=1 [[and {{city}}]]
order by city, callout_type;

-- Page 4: Value For Money
select city, value_index, median_price_usd, avg_rating
from airbnb.mart_value_for_money_city
where 1=1 [[and {{city}}]]
order by value_index desc;

select city, median_price_usd, avg_rating, listing_count
from airbnb.mart_city_market_landscape
where 1=1 [[and {{city}}]]
order by city;

select city, room_type, listing_count, median_price_usd, avg_rating, value_index
from airbnb.mart_city_room_value_segments
where 1=1 [[and {{city}}]] [[and {{room_type}}]]
order by value_index desc
limit 25;

select city, neighbourhood, listing_count, median_price_usd, avg_rating
from airbnb.mart_neighbourhood_value_drilldown
where 1=1 [[and {{city}}]]
order by avg_rating desc, median_price_usd asc
limit 50;
