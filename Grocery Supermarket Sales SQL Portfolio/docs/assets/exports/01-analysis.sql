-- Starter SQL for Grocery Supermarket Sales Performance Analytics Challenge
-- Primary target: SQL Server. Adapt date and top-N syntax for MySQL or BigQuery.
-- Purpose: build SQL marts for Power BI from the seven FMCG source CSV files.

-- Confirmed source path:
-- source-data/
-- Expected entities: sales, products, categories, customers, employees, cities, countries.
-- Source check found TotalPrice is zero in the cooked scan, so NetRevenue is
-- calculated as Quantity * products.Price * (1 - Discount).

with sales_enriched as (
    select
        s.SalesID,
        s.TransactionNumber as InvoiceID,
        cast(s.SalesDate as date) as SalesDate,
        datefromparts(year(cast(s.SalesDate as date)), month(cast(s.SalesDate as date)), 1) as SalesMonth,
        s.ProductID,
        s.CustomerID,
        s.SalesPersonID,
        p.CategoryID,
        p.Class as ProductClass,
        cu.CityID,
        ci.CountryID,
        cast(s.Quantity as decimal(18, 2)) as Quantity,
        cast(p.Price as decimal(18, 2)) as ProductPrice,
        cast(coalesce(s.Discount, 0) as decimal(18, 4)) as DiscountRate,
        cast(s.Quantity as decimal(18, 2)) * cast(p.Price as decimal(18, 2)) as GrossRevenueEstimate,
        case
            when cast(s.TotalPrice as decimal(18, 2)) <> 0
                then cast(s.TotalPrice as decimal(18, 2))
            else cast(s.Quantity as decimal(18, 2))
                * cast(p.Price as decimal(18, 2))
                * (1 - cast(coalesce(s.Discount, 0) as decimal(18, 4)))
        end as NetRevenue,
        cast(s.Quantity as decimal(18, 2)) * cast(p.Price as decimal(18, 2))
            - (
                cast(s.Quantity as decimal(18, 2))
                * cast(p.Price as decimal(18, 2))
                * (1 - cast(coalesce(s.Discount, 0) as decimal(18, 4)))
            ) as DiscountValueEstimate
    from sales s
    left join products p on s.ProductID = p.ProductID
    left join customers cu on s.CustomerID = cu.CustomerID
    left join cities ci on cu.CityID = ci.CityID
),
invoice_mart as (
    select
        InvoiceID,
        CustomerID,
        min(SalesDate) as InvoiceDate,
        sum(NetRevenue) as InvoiceNetRevenue,
        sum(Quantity) as BasketSize,
        count(*) as LineCount
    from sales_enriched
    group by InvoiceID, CustomerID
),
customer_segments as (
    select
        CustomerID,
        count(*) as InvoiceCount,
        sum(InvoiceNetRevenue) as CustomerNetRevenue,
        avg(InvoiceNetRevenue) as AverageOrderValue,
        avg(BasketSize) as AverageBasketSize,
        case
            when count(*) >= 2 then 'Repeat Customer'
            else 'One-time Buyer'
        end as CustomerType
    from invoice_mart
    group by CustomerID
),
monthly_category_revenue as (
    select
        SalesMonth,
        CategoryID,
        sum(NetRevenue) as NetRevenue,
        sum(GrossRevenueEstimate) as GrossRevenueEstimate,
        sum(Quantity) as UnitsSold,
        sum(NetRevenue) / nullif(sum(sum(NetRevenue)) over (partition by SalesMonth), 0) as CategoryShare
    from sales_enriched
    group by SalesMonth, CategoryID
),
product_performance as (
    select
        ProductID,
        sum(NetRevenue) as NetRevenue,
        sum(Quantity) as UnitsSold,
        sum(NetRevenue) / nullif(sum(Quantity), 0) as RevenuePerUnit,
        dense_rank() over (order by sum(NetRevenue) desc) as RevenueRankDesc,
        dense_rank() over (order by sum(NetRevenue) asc) as RevenueRankAsc
    from sales_enriched
    group by ProductID
),
employee_performance as (
    select
        SalesPersonID,
        SalesMonth,
        sum(GrossRevenueEstimate) as GrossRevenueEstimate,
        sum(NetRevenue) as NetRevenue,
        count(distinct InvoiceID) as InvoiceCount,
        sum(NetRevenue) / nullif(sum(sum(NetRevenue)) over (partition by SalesMonth), 0) as MonthlyContributionShare
    from sales_enriched
    group by SalesPersonID, SalesMonth
),
geo_market as (
    select
        CountryID,
        CityID,
        sum(NetRevenue) as NetRevenue,
        sum(Quantity) as UnitsSold,
        count(distinct CustomerID) as CustomerCount,
        count(distinct InvoiceID) as InvoiceCount
    from sales_enriched
    group by CountryID, CityID
)
select 'monthly_category_revenue' as MartName, count(*) as RowCount from monthly_category_revenue
union all
select 'product_performance', count(*) from product_performance
union all
select 'customer_segments', count(*) from customer_segments
union all
select 'employee_performance', count(*) from employee_performance
union all
select 'geo_market', count(*) from geo_market;
