/*
Step 03: business analysis queries for portfolio review.

Business context:
The snapshot window is January 1, 2018 through April 30, 2018. Revenue uses
the validated mart rule because the source TotalPrice field is zero:
NetRevenue = Quantity * ProductPrice * (1 - DiscountRate).
*/

use GrocerySupermarketSalesPortfolio;
go

declare @snapshot_start date = '2018-01-01';
declare @snapshot_end_exclusive date = '2018-05-01';
declare @snapshot_end date = dateadd(day, -1, @snapshot_end_exclusive);

-- 1. List every product category in the current catalog and the number of products in each category.
select
    c.CategoryName,
    count(p.ProductID) as ProductCount
from raw.categories c
left join raw.products p on c.CategoryID = p.CategoryID
group by c.CategoryName
order by c.CategoryName;

-- 2. Top 10 cities with the largest customer base for location planning.
select top (10)
    ci.CityName,
    co.CountryName,
    count(distinct cu.CustomerID) as CustomerCount
from raw.customers cu
inner join raw.cities ci on cu.CityID = ci.CityID
inner join raw.countries co on ci.CountryID = co.CountryID
group by ci.CityName, co.CountryName
order by CustomerCount desc, co.CountryName, ci.CityName;

-- 3. Highest-revenue month in the four-month snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select top (1)
    convert(char(7), MonthStart, 120) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD
from monthly_revenue
order by NetRevenue desc, MonthStart;

-- 4. Top 5 best-selling products within each category by total quantity sold.
;with product_units as (
    select
        CategoryName,
        ProductName,
        sum(Quantity) as TotalUnitsSold
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by CategoryName, ProductName
),
ranked_products as (
    select
        CategoryName,
        ProductName,
        TotalUnitsSold,
        dense_rank() over (
            partition by CategoryName
            order by TotalUnitsSold desc
        ) as CategoryRank
    from product_units
)
select
    CategoryName,
    ProductName,
    TotalUnitsSold,
    CategoryRank
from ranked_products
where CategoryRank <= 5
order by CategoryName, CategoryRank, ProductName;

-- 5. Average order value at invoice level, not sales-line level.
;with invoice_revenue as (
    select
        InvoiceID,
        sum(NetRevenue) as InvoiceRevenue
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by InvoiceID
)
select
    cast(avg(InvoiceRevenue) as decimal(18, 2)) as AverageOrderValueUSD
from invoice_revenue;

-- 6. Repeat customers versus one-time customers within the snapshot.
;with customer_invoice_counts as (
    select
        CustomerID,
        count(distinct InvoiceID) as InvoiceCount
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by CustomerID
),
customer_groups as (
    select
        case
            when InvoiceCount >= 2 then 'Repeat'
            else 'One-time'
        end as CustomerGroup,
        count(*) as CustomerCount
    from customer_invoice_counts
    group by case when InvoiceCount >= 2 then 'Repeat' else 'One-time' end
),
segment_labels as (
    select 'Repeat' as CustomerGroup, 1 as SortOrder
    union all
    select 'One-time', 2
)
select
    sl.CustomerGroup,
    coalesce(cg.CustomerCount, 0) as CustomerCount,
    cast(
        100.0 * coalesce(cg.CustomerCount, 0)
        / nullif(sum(coalesce(cg.CustomerCount, 0)) over (), 0)
        as decimal(5, 2)
    ) as CustomerSharePct
from segment_labels sl
left join customer_groups cg on sl.CustomerGroup = cg.CustomerGroup
order by sl.SortOrder;

-- 7. Average cashier tenure in working days by gender as of April 30, 2018.
select
    Gender,
    cast(avg(cast(datediff(day, cast(HireDate as date), @snapshot_end) as decimal(18, 2))) as decimal(18, 2)) as AverageWorkingDays
from raw.employees
where HireDate is not null
group by Gender
order by Gender;

-- 8. Catalog SKUs with no sales lines in the four-month snapshot.
;with sold_products as (
    select distinct ProductID
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
)
select
    p.ProductID as SKU,
    p.ProductName,
    c.CategoryName,
    cast(p.Price as decimal(18, 2)) as ListPriceUSD
from raw.products p
left join raw.categories c on p.CategoryID = c.CategoryID
left join sold_products sp on p.ProductID = sp.ProductID
where sp.ProductID is null
order by c.CategoryName, p.ProductName;

-- 9. Monthly revenue and cumulative revenue from the start of the snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as MonthlyRevenueUSD,
    cast(sum(NetRevenue) over (order by MonthStart rows unbounded preceding) as decimal(18, 2)) as CumulativeRevenueUSD
from monthly_revenue
order by MonthStart;

-- 10. Customer quartiles by total spend.
;with customer_spend as (
    select
        CustomerID,
        sum(NetRevenue) as TotalSpend
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by CustomerID
),
ranked_customers as (
    select
        CustomerID,
        TotalSpend,
        ntile(4) over (order by TotalSpend desc, CustomerID) as SpendQuartile
    from customer_spend
),
quartile_labels as (
    select
        case SpendQuartile
            when 1 then 'Highest spenders (top 25%)'
            when 2 then 'Above-average spenders'
            when 3 then 'Below-average spenders'
            else 'Lowest spenders'
        end as CustomerSegment,
        SpendQuartile,
        count(*) as CustomerCount,
        sum(TotalSpend) as SegmentTotalSpend,
        avg(TotalSpend) as AverageSpendPerCustomer
    from ranked_customers
    group by SpendQuartile
)
select
    CustomerSegment,
    CustomerCount,
    cast(SegmentTotalSpend as decimal(18, 2)) as SegmentTotalSpendUSD,
    cast(AverageSpendPerCustomer as decimal(18, 2)) as AverageSpendPerCustomerUSD
from quartile_labels
order by SpendQuartile;

-- 11. Monthly category revenue mix for stacked-bar reporting.
;with monthly_category_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        CategoryName,
        sum(NetRevenue) as NetRevenue
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by datefromparts(year(SalesDate), month(SalesDate), 1), CategoryName
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    CategoryName,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD,
    cast(100.0 * NetRevenue / nullif(sum(NetRevenue) over (partition by MonthStart), 0) as decimal(6, 2)) as MonthlyRevenueSharePct
from monthly_category_revenue
order by MonthStart, CategoryName;

-- 12. Best rolling 30-day revenue window achieved by each employee.
;with date_spine as (
    select
        @snapshot_start as SalesDay
    union all
    select
        dateadd(day, 1, SalesDay)
    from date_spine
    where SalesDay < dateadd(day, -1, @snapshot_end_exclusive)
),
employee_days as (
    select
        e.EmployeeID,
        concat(e.FirstName, ' ', e.LastName) as EmployeeName,
        d.SalesDay
    from raw.employees e
    cross join date_spine d
),
daily_employee_revenue as (
    select
        s.SalesPersonID as EmployeeID,
        cast(try_convert(datetime2, nullif(s.SalesDate, '')) as date) as SalesDay,
        sum(
            cast(s.Quantity as decimal(18, 2))
            * cast(p.Price as decimal(18, 4))
            * (1 - cast(coalesce(s.Discount, 0) as decimal(9, 4)))
        ) as DailyRevenue
    from raw.sales s
    inner join raw.products p on s.ProductID = p.ProductID
    where try_convert(datetime2, nullif(s.SalesDate, '')) >= @snapshot_start
        and try_convert(datetime2, nullif(s.SalesDate, '')) < @snapshot_end_exclusive
    group by
        s.SalesPersonID,
        cast(try_convert(datetime2, nullif(s.SalesDate, '')) as date)
),
rolling_windows as (
    select
        ed.EmployeeID,
        ed.EmployeeName,
        ed.SalesDay as WindowStartDate,
        sum(coalesce(der.DailyRevenue, 0)) over (
            partition by ed.EmployeeID
            order by ed.SalesDay
            rows between current row and 29 following
        ) as Rolling30DayRevenue
    from employee_days ed
    left join daily_employee_revenue der
        on ed.EmployeeID = der.EmployeeID
        and ed.SalesDay = der.SalesDay
),
ranked_windows as (
    select
        EmployeeID,
        EmployeeName,
        WindowStartDate,
        Rolling30DayRevenue,
        row_number() over (
            partition by EmployeeID
            order by Rolling30DayRevenue desc, WindowStartDate
        ) as WindowRank
    from rolling_windows
)
select
    EmployeeID,
    EmployeeName,
    cast(Rolling30DayRevenue as decimal(18, 2)) as MaxRolling30DayRevenueUSD,
    WindowStartDate
from ranked_windows
where WindowRank = 1
order by MaxRolling30DayRevenueUSD desc, EmployeeName
option (maxrecursion 0, hash group);

-- 13. Basket-analysis readiness check and top same-invoice product pairs.
;with invoice_product_counts as (
    select
        InvoiceID,
        count(distinct ProductID) as DistinctProductCount
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
    group by InvoiceID
)
select
    count(*) as TotalInvoices,
    sum(case when DistinctProductCount >= 2 then 1 else 0 end) as MultiProductInvoices,
    cast(100.0 * sum(case when DistinctProductCount >= 2 then 1 else 0 end) / nullif(count(*), 0) as decimal(6, 4)) as MultiProductInvoiceSharePct,
    case
        when sum(case when DistinctProductCount >= 2 then 1 else 0 end) = 0
            then 'No same-invoice product pairs are available because each invoice has one distinct product in this dataset.'
        else 'Same-invoice product pairs are available.'
    end as BasketAnalysisStatus
from invoice_product_counts;

-- Requested output: top 20 product pairs most often bought together in the same invoice.
;with invoice_products as (
    select distinct
        InvoiceID,
        ProductID,
        ProductName
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
),
eligible_invoices as (
    select InvoiceID
    from invoice_products
    group by InvoiceID
    having count(distinct ProductID) >= 2
),
total_invoices as (
    select count(distinct InvoiceID) as InvoiceCount
    from mart.vw_sales_enriched
    where SalesDate >= @snapshot_start
        and SalesDate < @snapshot_end_exclusive
),
product_pairs as (
    select
        a.ProductName as ProductA,
        b.ProductName as ProductB,
        count(*) as CoPurchaseCount
    from invoice_products a
    inner join invoice_products b
        on a.InvoiceID = b.InvoiceID
        and a.ProductID < b.ProductID
    inner join eligible_invoices ei on a.InvoiceID = ei.InvoiceID
    group by a.ProductName, b.ProductName
)
select top (20)
    ProductA,
    ProductB,
    CoPurchaseCount,
    cast(100.0 * CoPurchaseCount / nullif(t.InvoiceCount, 0) as decimal(6, 4)) as ShareOfAllInvoicesPct
from product_pairs
cross join total_invoices t
order by CoPurchaseCount desc, ProductA, ProductB;
