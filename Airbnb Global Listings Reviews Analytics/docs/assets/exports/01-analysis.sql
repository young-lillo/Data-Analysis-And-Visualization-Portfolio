-- Supabase/Postgres model contract for Airbnb Global Listings & Reviews.
-- Keep credentials in environment/runtime config, never in this file.

create schema if not exists airbnb;

create table if not exists airbnb.stg_listings (
  listing_id bigint primary key,
  name text,
  host_id bigint,
  host_since date,
  host_location text,
  host_response_time text,
  host_response_rate text,
  host_acceptance_rate text,
  host_is_superhost boolean,
  host_total_listings_count integer,
  host_has_profile_pic boolean,
  host_identity_verified boolean,
  neighbourhood text,
  district text,
  city text not null,
  latitude double precision,
  longitude double precision,
  property_type text,
  room_type text,
  accommodates integer,
  bedrooms integer,
  amenities text,
  price numeric,
  minimum_nights integer,
  maximum_nights integer,
  review_scores_rating numeric,
  review_scores_accuracy numeric,
  review_scores_cleanliness numeric,
  review_scores_checkin numeric,
  review_scores_communication numeric,
  review_scores_location numeric,
  review_scores_value numeric,
  instant_bookable boolean
);

create table if not exists airbnb.stg_reviews (
  listing_id bigint not null,
  review_id bigint primary key,
  date date not null,
  reviewer_id bigint
);

create table if not exists airbnb.dim_currency_rate (
  currency_code text primary key,
  local_per_usd numeric not null,
  rate_year integer not null,
  rate_method text not null default 'fixed 2020 annual average'
);

insert into airbnb.dim_currency_rate (currency_code, local_per_usd, rate_year)
values
  ('USD', 1.000, 2020),
  ('EUR', 0.877, 2020),
  ('AUD', 1.452, 2020),
  ('BRL', 5.158, 2020),
  ('TRY', 7.009, 2020),
  ('MXN', 21.487, 2020),
  ('THB', 31.294, 2020),
  ('ZAR', 16.459, 2020),
  ('HKD', 7.756, 2020)
on conflict (currency_code) do update
set local_per_usd = excluded.local_per_usd,
    rate_year = excluded.rate_year,
    rate_method = excluded.rate_method;

create or replace view airbnb.dim_city as
select *
from (
  values
    ('Paris', 'EUR'),
    ('New York', 'USD'),
    ('Sydney', 'AUD'),
    ('Rome', 'EUR'),
    ('Rio de Janeiro', 'BRL'),
    ('Istanbul', 'TRY'),
    ('Mexico City', 'MXN'),
    ('Bangkok', 'THB'),
    ('Cape Town', 'ZAR'),
    ('Hong Kong', 'HKD')
) as c(city, currency_code);

create or replace view airbnb.dim_listing as
select
  l.*,
  c.currency_code,
  r.local_per_usd,
  l.price / nullif(r.local_per_usd, 0) as price_usd
from airbnb.stg_listings l
join airbnb.dim_city c on c.city = l.city
join airbnb.dim_currency_rate r on r.currency_code = c.currency_code;

create index if not exists idx_airbnb_listings_city on airbnb.stg_listings (city);
create index if not exists idx_airbnb_reviews_listing_id on airbnb.stg_reviews (listing_id);
create index if not exists idx_airbnb_reviews_date on airbnb.stg_reviews (date);

create or replace view airbnb.fact_review_activity as
select
  l.city,
  date_trunc('month', r.date)::date as review_month,
  count(*) as review_count
from airbnb.stg_reviews r
join airbnb.dim_listing l on l.listing_id = r.listing_id
group by 1, 2;

create or replace view airbnb.mart_city_market_landscape as
select
  city,
  count(*) as listing_count,
  percentile_cont(0.5) within group (order by price_usd) as median_price_usd,
  percentile_cont(0.25) within group (order by price_usd) as p25_price_usd,
  percentile_cont(0.75) within group (order by price_usd) as p75_price_usd,
  avg(review_scores_rating) as avg_rating,
  avg(case when host_is_superhost then 1 else 0 end) as superhost_share
from airbnb.dim_listing
group by 1;

create or replace view airbnb.mart_room_type_mix as
select city, room_type, count(*) as listing_count
from airbnb.dim_listing
group by 1, 2;

create or replace view airbnb.mart_monthly_tourism_pulse as
with baseline as (
  select city, avg(review_count) as baseline_2019_avg
  from airbnb.fact_review_activity
  where review_month >= date '2019-01-01' and review_month < date '2020-01-01'
  group by 1
)
select
  a.city,
  a.review_month,
  a.review_count,
  b.baseline_2019_avg,
  a.review_count / nullif(b.baseline_2019_avg, 0) as recovery_index
from airbnb.fact_review_activity a
left join baseline b on b.city = a.city;

create or replace view airbnb.mart_value_for_money as
with city_stats as (
  select
    city,
    percentile_cont(0.5) within group (order by price_usd) as median_price_usd,
    avg(review_scores_rating) as avg_rating
  from airbnb.dim_listing
  group by 1
),
limits as (
  select min(median_price_usd) as min_price, max(median_price_usd) as max_price
  from city_stats
)
select
  c.city,
  c.median_price_usd,
  c.avg_rating,
  1 - ((c.median_price_usd - l.min_price) / nullif(l.max_price - l.min_price, 0)) as affordability_score,
  c.avg_rating / 100 as rating_score,
  ((c.avg_rating / 100) * 0.6)
    + ((1 - ((c.median_price_usd - l.min_price) / nullif(l.max_price - l.min_price, 0))) * 0.4) as value_index
from city_stats c
cross join limits l;
