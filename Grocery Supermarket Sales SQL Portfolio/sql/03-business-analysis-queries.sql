/*
Step 03: business analysis queries for portfolio review.
*/

use GrocerySupermarketSalesPortfolio;
go

-- 1. Executive KPI summary.
select
    NetRevenue,
    GrossRevenueEstimate,
    UnitsSold,
    SalesLineCount,
    InvoiceCount,
    CustomerCount,
    AverageOrderValue,
    AverageBasketSize
from mart.vw_executive_kpis;

-- 2. Category month-over-month performance.
select
    SalesMonth,
    CategoryName,
    NetRevenue,
    CategoryShare,
    MoMRevenueChange,
    MoMRevenueChangePct
from mart.vw_monthly_category_revenue
where SalesMonth <> 'Unknown'
order by SalesMonth, NetRevenue desc;

-- 3. Top 5 products by calculated net revenue.
select top (5)
    ProductID,
    ProductName,
    CategoryName,
    ProductClass,
    NetRevenue,
    UnitsSold,
    RevenuePerUnit
from mart.vw_product_performance
order by NetRevenue desc, ProductID;

-- 4. Bottom 5 products by calculated net revenue.
select top (5)
    ProductID,
    ProductName,
    CategoryName,
    ProductClass,
    NetRevenue,
    UnitsSold,
    RevenuePerUnit
from mart.vw_product_performance
order by NetRevenue asc, ProductID;

-- 5. Quantity versus revenue: high-volume low-yield products.
;with product_threshold as (
    select distinct
        percentile_cont(0.75) within group (order by UnitsSold)
            over () as UnitsSoldP75
    from mart.vw_product_performance
)
select top (20)
    p.ProductName,
    p.CategoryName,
    p.ProductClass,
    p.UnitsSold,
    p.NetRevenue,
    p.RevenuePerUnit
from mart.vw_product_performance p
cross join product_threshold t
where p.UnitsSold >= t.UnitsSoldP75
order by p.RevenuePerUnit asc;

-- 6. Class impact on consumption performance.
select
    Class,
    NetRevenue,
    UnitsSold,
    RevenuePerUnit,
    NetRevenue / nullif(sum(NetRevenue) over (), 0) as RevenueShare
from mart.vw_class_performance
order by NetRevenue desc;

-- 7. Customer segmentation by value and frequency.
select top (50)
    CustomerID,
    CustomerName,
    CustomerType,
    InvoiceCount,
    NetRevenue,
    AverageOrderValue,
    AverageBasketSize
from mart.vw_customer_segments
order by NetRevenue desc;

-- 8. Repeat versus one-time buyer mix.
select
    CustomerType,
    count(*) as CustomerCount,
    sum(NetRevenue) as NetRevenue,
    sum(NetRevenue) / nullif(sum(InvoiceCount), 0) as SegmentAverageOrderValue,
    sum(UnitsSold) / nullif(sum(InvoiceCount), 0) as SegmentAverageBasketSize,
    avg(AverageOrderValue) as AvgCustomerAOV,
    avg(AverageBasketSize) as AvgBasketSize
from mart.vw_customer_segments
group by CustomerType
order by NetRevenue desc;

-- 9. Employee performance ranking.
select
    EmployeeID,
    EmployeeName,
    sum(NetRevenue) as NetRevenue,
    sum(InvoiceCount) as InvoiceCount,
    sum(UnitsSold) as UnitsSold,
    dense_rank() over (order by sum(NetRevenue) desc) as RevenueRank
from mart.vw_employee_performance
group by EmployeeID, EmployeeName
order by RevenueRank;

-- 10. Employee contribution over time.
select
    SalesMonth,
    EmployeeName,
    NetRevenue,
    InvoiceCount,
    MonthlyContributionShare
from mart.vw_employee_performance
where SalesMonth <> 'Unknown'
order by SalesMonth, NetRevenue desc;

-- 11. Geographic market ranking.
select top (20)
    CountryName,
    CityName,
    NetRevenue,
    UnitsSold,
    CustomerCount,
    InvoiceCount,
    NetRevenue / nullif(sum(NetRevenue) over (), 0) as MarketRevenueShare
from mart.vw_geo_market
order by NetRevenue desc;

-- 12. Expansion signal: high unit demand versus revenue.
select top (20)
    CountryName,
    CityName,
    UnitsSold,
    NetRevenue,
    NetRevenue / nullif(UnitsSold, 0) as RevenuePerUnit
from mart.vw_geo_market
where UnitsSold > 0
order by UnitsSold desc, RevenuePerUnit asc;
