/*
Step 04: validation and data quality queries.
*/

use GrocerySupermarketSalesPortfolio;
go

-- 1. Source row counts.
select
    'categories' as TableName,
    count(*) as [RowCount]
from raw.categories
union all
select 'countries', count(*) from raw.countries
union all
select 'cities', count(*) from raw.cities
union all
select 'customers', count(*) from raw.customers
union all
select 'employees', count(*) from raw.employees
union all
select 'products', count(*) from raw.products
union all
select 'sales', count(*) from raw.sales;

-- 2. Primary key duplicate checks.
select 'raw.sales.SalesID' as CheckName, SalesID, count(*) as DuplicateCount
from raw.sales
group by SalesID
having count(*) > 1;

-- 3. Foreign key coverage checks.
select 'Sales without product' as CheckName, count(*) as [RowCount]
from raw.sales s
left join raw.products p on s.ProductID = p.ProductID
where p.ProductID is null
union all
select 'Sales without customer', count(*)
from raw.sales s
left join raw.customers c on s.CustomerID = c.CustomerID
where c.CustomerID is null
union all
select 'Sales without employee', count(*)
from raw.sales s
left join raw.employees e on s.SalesPersonID = e.EmployeeID
where e.EmployeeID is null;

-- 4. Revenue source quality.
select
    count(*) as SalesRows,
    sum(case when coalesce(TotalPrice, 0) = 0 then 1 else 0 end) as ZeroTotalPriceRows,
    sum(case when parsed.SalesDate is null then 1 else 0 end) as BlankSalesDateRows,
    min(parsed.SalesDate) as MinSalesDate,
    max(parsed.SalesDate) as MaxSalesDate
from raw.sales s
cross apply (values (try_convert(datetime2, nullif(s.SalesDate, '')))) parsed(SalesDate);

-- 5. Mart reconciliation.
select
    'sales_enriched_vs_executive_kpis' as CheckName,
    enriched.EnrichedNetRevenue,
    executive.ExecutiveNetRevenue,
    enriched.EnrichedNetRevenue - executive.ExecutiveNetRevenue as Difference
from (
    select sum(NetRevenue) as EnrichedNetRevenue
    from mart.vw_sales_enriched
) enriched
cross join (
    select NetRevenue as ExecutiveNetRevenue
    from mart.vw_executive_kpis
) executive;

-- 6. Expected cooked portfolio targets.
select
    case when count(*) = 6758125 then 'PASS' else 'CHECK' end as SalesRowCountCheck,
    count(*) as SalesRows
from raw.sales;

select
    case
        when round(NetRevenue, 2) = cast(4332445646.06 as decimal(18, 2)) then 'PASS'
        else 'CHECK'
    end as NetRevenueCheck,
    NetRevenue
from mart.vw_executive_kpis;

-- 7. Month bucket quality.
select
    SalesMonth,
    count(*) as SalesLines,
    sum(NetRevenue) as NetRevenue
from mart.vw_sales_enriched
group by SalesMonth
order by SalesMonth;
