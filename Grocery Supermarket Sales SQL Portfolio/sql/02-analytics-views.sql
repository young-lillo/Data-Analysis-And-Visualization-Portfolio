/*
Step 02: create analytics views for Power BI and SQL analysis.
*/

use GrocerySupermarketSalesPortfolio;
go

create or alter view mart.vw_sales_enriched as
with sales_prepared as (
    select
        s.SalesID,
        s.TransactionNumber,
        s.ProductID,
        s.CustomerID,
        s.SalesPersonID,
        s.TotalPrice,
        parsed.SalesDate,
        case
            when parsed.SalesDate is null then 'Unknown'
            else convert(char(7), parsed.SalesDate, 120)
        end as SalesMonth,
        cast(s.Quantity as decimal(18, 2)) as Quantity,
        cast(coalesce(s.Discount, 0) as decimal(9, 4)) as DiscountRate,
        case when coalesce(s.TotalPrice, 0) = 0 then 1 else 0 end as UsedCalculatedRevenueFlag
    from raw.sales s
    cross apply (values (try_convert(datetime2, nullif(s.SalesDate, '')))) parsed(SalesDate)
)
select
    sp.SalesID,
    sp.TransactionNumber as InvoiceID,
    sp.SalesDate,
    sp.SalesMonth,
    sp.ProductID,
    p.ProductName,
    p.CategoryID,
    c.CategoryName,
    p.Class as ProductClass,
    sp.CustomerID,
    concat(cu.FirstName, ' ', cu.LastName) as CustomerName,
    sp.SalesPersonID as EmployeeID,
    concat(e.FirstName, ' ', e.LastName) as EmployeeName,
    ci.CityID,
    ci.CityName,
    co.CountryID,
    co.CountryName,
    sp.Quantity,
    cast(p.Price as decimal(18, 4)) as ProductPrice,
    sp.DiscountRate,
    sp.Quantity * cast(p.Price as decimal(18, 4)) as GrossRevenueEstimate,
    case
        when sp.UsedCalculatedRevenueFlag = 0 then cast(sp.TotalPrice as decimal(18, 4))
        else sp.Quantity * cast(p.Price as decimal(18, 4)) * (1 - sp.DiscountRate)
    end as NetRevenue,
    sp.UsedCalculatedRevenueFlag
from sales_prepared sp
left join raw.products p on sp.ProductID = p.ProductID
left join raw.categories c on p.CategoryID = c.CategoryID
left join raw.customers cu on sp.CustomerID = cu.CustomerID
left join raw.employees e on sp.SalesPersonID = e.EmployeeID
left join raw.cities ci on cu.CityID = ci.CityID
left join raw.countries co on ci.CountryID = co.CountryID;
go

create or alter view mart.vw_executive_kpis as
select
    sum(NetRevenue) as NetRevenue,
    sum(GrossRevenueEstimate) as GrossRevenueEstimate,
    sum(Quantity) as UnitsSold,
    count(*) as SalesLineCount,
    count(distinct InvoiceID) as InvoiceCount,
    count(distinct CustomerID) as CustomerCount,
    sum(NetRevenue) / nullif(count(distinct InvoiceID), 0) as AverageOrderValue,
    sum(Quantity) / nullif(count(distinct InvoiceID), 0) as AverageBasketSize
from mart.vw_sales_enriched;
go

create or alter view mart.vw_monthly_category_revenue as
with monthly as (
    select
        SalesMonth,
        CategoryID,
        CategoryName,
        sum(NetRevenue) as NetRevenue,
        sum(GrossRevenueEstimate) as GrossRevenueEstimate,
        sum(Quantity) as UnitsSold
    from mart.vw_sales_enriched
    group by SalesMonth, CategoryID, CategoryName
),
monthly_with_history as (
    select
        SalesMonth,
        CategoryID,
        CategoryName,
        NetRevenue,
        GrossRevenueEstimate,
        UnitsSold,
        lag(NetRevenue) over (partition by CategoryID order by SalesMonth) as PreviousNetRevenue
    from monthly
)
select
    SalesMonth,
    CategoryID,
    CategoryName,
    NetRevenue,
    GrossRevenueEstimate,
    UnitsSold,
    NetRevenue / nullif(sum(NetRevenue) over (partition by SalesMonth), 0) as CategoryShare,
    NetRevenue - PreviousNetRevenue as MoMRevenueChange,
    (NetRevenue - PreviousNetRevenue) / nullif(PreviousNetRevenue, 0) as MoMRevenueChangePct
from monthly_with_history;
go

create or alter view mart.vw_product_performance as
with product_rollup as (
    select
        ProductID,
        ProductName,
        CategoryName,
        ProductClass,
        sum(NetRevenue) as NetRevenue,
        sum(GrossRevenueEstimate) as GrossRevenueEstimate,
        sum(Quantity) as UnitsSold
    from mart.vw_sales_enriched
    group by ProductID, ProductName, CategoryName, ProductClass
)
select
    ProductID,
    ProductName,
    CategoryName,
    ProductClass,
    NetRevenue,
    GrossRevenueEstimate,
    UnitsSold,
    NetRevenue / nullif(UnitsSold, 0) as RevenuePerUnit,
    dense_rank() over (order by NetRevenue desc) as RevenueRankDesc,
    dense_rank() over (order by NetRevenue asc) as RevenueRankAsc
from product_rollup;
go

create or alter view mart.vw_customer_segments as
with customer_rollup as (
    select
        CustomerID,
        max(CustomerName) as CustomerName,
        count(distinct InvoiceID) as InvoiceCount,
        sum(NetRevenue) as NetRevenue,
        sum(Quantity) as UnitsSold
    from mart.vw_sales_enriched
    group by CustomerID
)
select
    CustomerID,
    CustomerName,
    InvoiceCount,
    NetRevenue,
    UnitsSold,
    case when InvoiceCount >= 2 then 'Repeat Customer' else 'One-time Buyer' end as CustomerType,
    NetRevenue / nullif(InvoiceCount, 0) as AverageOrderValue,
    UnitsSold / nullif(InvoiceCount, 0) as AverageBasketSize
from customer_rollup;
go

create or alter view mart.vw_employee_performance as
with employee_monthly as (
    select
        EmployeeID,
        EmployeeName,
        SalesMonth,
        sum(NetRevenue) as NetRevenue,
        count(distinct InvoiceID) as InvoiceCount,
        sum(Quantity) as UnitsSold
    from mart.vw_sales_enriched
    group by EmployeeID, EmployeeName, SalesMonth
)
select
    EmployeeID,
    EmployeeName,
    SalesMonth,
    NetRevenue,
    InvoiceCount,
    UnitsSold,
    NetRevenue / nullif(sum(NetRevenue) over (partition by SalesMonth), 0) as MonthlyContributionShare
from employee_monthly;
go

create or alter view mart.vw_geo_market as
select
    CountryID,
    CountryName,
    CityID,
    CityName,
    sum(NetRevenue) as NetRevenue,
    sum(Quantity) as UnitsSold,
    count(distinct CustomerID) as CustomerCount,
    count(distinct InvoiceID) as InvoiceCount
from mart.vw_sales_enriched
group by CountryID, CountryName, CityID, CityName;
go

create or alter view mart.vw_class_performance as
select
    ProductClass as Class,
    sum(NetRevenue) as NetRevenue,
    sum(GrossRevenueEstimate) as GrossRevenueEstimate,
    sum(Quantity) as UnitsSold,
    count(*) as LineCount,
    sum(NetRevenue) / nullif(sum(Quantity), 0) as RevenuePerUnit
from mart.vw_sales_enriched
group by ProductClass;
go
