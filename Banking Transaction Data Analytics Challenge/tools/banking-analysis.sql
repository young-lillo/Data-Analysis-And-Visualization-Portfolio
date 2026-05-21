-- DuckDB-style starter SQL for the cooked Power BI CSV outputs.
-- Update file paths if running outside the project folder.

create or replace view fact_banking_transactions as
select *
from read_csv_auto('banking-transactions-prepared-usd.csv');

-- Executive KPI check
select
  count(*) as transactions,
  count(distinct CustomerID) as distinct_customers,
  round(sum(AmountUSD), 2) as total_amount_usd,
  round(sum(TotalFeesUSD), 2) as total_fees_usd,
  round(sum(LatePaymentAmountUSD), 2) as late_payment_usd
from fact_banking_transactions;

-- Segment activity and fee burden
select
  CustomerSegment,
  count(*) as transactions,
  count(distinct CustomerID) as customers,
  round(sum(AmountUSD), 2) as total_amount_usd,
  round(sum(TotalFeesUSD), 2) as total_fees_usd,
  round(sum(TotalFeesUSD) / nullif(sum(AmountUSD), 0), 4) as fee_rate
from fact_banking_transactions
group by CustomerSegment
order by transactions desc;

-- Transaction type count versus value
select
  TransactionType,
  count(*) as transactions,
  round(sum(AmountUSD), 2) as total_amount_usd,
  round(sum(TotalFeesUSD), 2) as total_fees_usd
from fact_banking_transactions
group by TransactionType
order by total_amount_usd desc;
