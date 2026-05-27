# Practice SQL Answers

## Practice Questions

1. Which product categories are in the current catalog, and how many products are in each category?
2. Which 10 cities have the largest customer base for location planning?
3. Which month produced the highest revenue in the January-April 2018 snapshot?
4. What are the best-selling products inside each category by total units sold?
5. What is the average order value at invoice level?
6. What share of customers are repeat buyers versus one-time buyers?
7. What is the average cashier tenure by gender as of April 30, 2018?
8. Which catalog SKUs had no sales lines during the snapshot?
9. What are monthly revenue and cumulative revenue across the snapshot?
10. How do customers split into four spend quartiles?
11. What is each category's monthly revenue share?
12. What is each employee's best rolling 30-day revenue window?
13. Which product pairs are most frequently bought together in one invoice?

## SQL Answers For Practice Questions

```sql
/*
SQL answers for the 13 Practice Questions above.

Tables:
fmcg_sales.categories
fmcg_sales.cities
fmcg_sales.countries
fmcg_sales.customers
fmcg_sales.employees
fmcg_sales.products
fmcg_sales.sales

Revenue is recalculated because sales.total_price is not reliable:
NetRevenue = quantity * price * (1 - discount)
*/

declare @snapshot_start date = '2018-01-01';
declare @snapshot_end_exclusive date = '2018-05-01';
declare @snapshot_end date = dateadd(day, -1, @snapshot_end_exclusive);

drop table if exists #practice_sales_enriched;

select
    s.sales_id as SalesID,
    s.transaction_number as InvoiceID,
    s.sales_date as SalesDate,
    s.product_id as ProductID,
    p.product_name as ProductName,
    p.category_id as CategoryID,
    c.category_name as CategoryName,
    s.customer_id as CustomerID,
    s.salesperson_id as EmployeeID,
    concat(e.first_name, ' ', e.last_name) as EmployeeName,
    cast(s.quantity as decimal(18, 2)) as Quantity,
    cast(p.price as decimal(18, 4)) as ProductPrice,
    cast(coalesce(s.discount, 0) as decimal(9, 4)) as DiscountRate,
    cast(s.quantity as decimal(18, 2))
        * cast(p.price as decimal(18, 4))
        * (1 - cast(coalesce(s.discount, 0) as decimal(9, 4))) as NetRevenue
into #practice_sales_enriched
from fmcg_sales.sales s
left join fmcg_sales.products p on s.product_id = p.product_id
left join fmcg_sales.categories c on p.category_id = c.category_id
left join fmcg_sales.employees e on s.salesperson_id = e.employee_id
where s.sales_date >= @snapshot_start
    and s.sales_date < @snapshot_end_exclusive;

-- P1. Product categories in the current catalog and product count in each category.
select
    c.category_name as CategoryName,
    count(p.product_id) as ProductCount
from fmcg_sales.categories c
left join fmcg_sales.products p on c.category_id = p.category_id
group by c.category_name
order by c.category_name;

-- P2. Top 10 cities with the largest customer base for location planning.
select top (10)
    ci.city_name as CityName,
    co.country_name as CountryName,
    count(distinct cu.customer_id) as CustomerCount
from fmcg_sales.customers cu
inner join fmcg_sales.cities ci on cu.city_id = ci.city_id
inner join fmcg_sales.countries co on ci.country_id = co.country_id
group by ci.city_name, co.country_name
order by CustomerCount desc, co.country_name, ci.city_name;

-- P3. Highest-revenue month in the January-April 2018 snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from #practice_sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select top (1)
    convert(char(7), MonthStart, 120) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD
from monthly_revenue
order by NetRevenue desc, MonthStart;

-- P4. Top 5 best-selling products inside each category by total units sold.
;with product_units as (
    select
        CategoryName,
        ProductName,
        sum(Quantity) as TotalUnitsSold
    from #practice_sales_enriched
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

-- P5. Average order value at invoice level.
;with invoice_revenue as (
    select
        InvoiceID,
        sum(NetRevenue) as InvoiceRevenue
    from #practice_sales_enriched
    group by InvoiceID
)
select
    cast(avg(InvoiceRevenue) as decimal(18, 2)) as AverageOrderValueUSD
from invoice_revenue;

-- P6. Repeat buyers versus one-time buyers.
;with customer_invoice_counts as (
    select
        CustomerID,
        count(distinct InvoiceID) as InvoiceCount
    from #practice_sales_enriched
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

-- P7. Average cashier tenure by gender as of April 30, 2018.
  select
      gender as Gender,
      cast(avg(cast(datediff(day, cast(hire_date as date), '2018-04-30') as decimal(18, 2))) as decimal(18, 2)) as AverageWorkingDays
  from fmcg_sales.employees
  where hire_date is not null
  group by gender
  order by gender;

-- P8. Catalog SKUs with no sales lines during the snapshot.
;with sold_products as (
    select distinct ProductID
    from #practice_sales_enriched
)
select
    p.product_id as SKU,
    p.product_name as ProductName,
    c.category_name as CategoryName,
    cast(p.price as decimal(18, 2)) as ListPriceUSD
from fmcg_sales.products p
left join fmcg_sales.categories c on p.category_id = c.category_id
left join sold_products sp on p.product_id = sp.ProductID
where sp.ProductID is null
order by c.category_name, p.product_name;

-- P9. Monthly revenue and cumulative revenue across the snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from #practice_sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as MonthlyRevenueUSD,
    cast(sum(NetRevenue) over (order by MonthStart rows unbounded preceding) as decimal(18, 2)) as CumulativeRevenueUSD
from monthly_revenue
order by MonthStart;

-- P10. Customer spend quartiles.
;with customer_spend as (
    select
        CustomerID,
        sum(NetRevenue) as TotalSpend
    from #practice_sales_enriched
    group by CustomerID
),
ranked_customers as (
    select
        CustomerID,
        TotalSpend,
        ntile(4) over (order by TotalSpend desc, CustomerID) as SpendQuartile
    from customer_spend
),
quartile_rollup as (
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
from quartile_rollup
order by SpendQuartile;

-- P11. Monthly revenue share for each category.
;with monthly_category_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        CategoryName,
        sum(NetRevenue) as NetRevenue
    from #practice_sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1), CategoryName
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    CategoryName,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD,
    cast(100.0 * NetRevenue / nullif(sum(NetRevenue) over (partition by MonthStart), 0) as decimal(6, 2)) as MonthlyRevenueSharePct
from monthly_category_revenue
order by MonthStart, CategoryName;

-- P12. Best rolling 30-day revenue window for each employee.
;with date_spine as (
    select @snapshot_start as SalesDay
    union all
    select dateadd(day, 1, SalesDay)
    from date_spine
    where SalesDay < @snapshot_end
),
employee_days as (
    select
        e.employee_id as EmployeeID,
        concat(e.first_name, ' ', e.last_name) as EmployeeName,
        d.SalesDay
    from fmcg_sales.employees e
    cross join date_spine d
),
daily_employee_revenue as (
    select
        EmployeeID,
        cast(SalesDate as date) as SalesDay,
        sum(NetRevenue) as DailyRevenue
    from #practice_sales_enriched
    group by EmployeeID, cast(SalesDate as date)
),
rolling_windows as (
    select
        ed.EmployeeID,
        ed.EmployeeName,
        ed.SalesDay as WindowStartDate,
        sum(coalesce(der.DailyRevenue, 0)) as Rolling30DayRevenue
    from employee_days ed
    left join daily_employee_revenue der
        on ed.EmployeeID = der.EmployeeID
        and der.SalesDay >= ed.SalesDay
        and der.SalesDay < dateadd(day, 30, ed.SalesDay)
    group by ed.EmployeeID, ed.EmployeeName, ed.SalesDay
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

-- P13. Top 20 product pairs most frequently bought together in one invoice.
;with invoice_products as (
    select distinct
        InvoiceID,
        ProductID,
        ProductName
    from #practice_sales_enriched
),
eligible_invoices as (
    select InvoiceID
    from invoice_products
    group by InvoiceID
    having count(distinct ProductID) >= 2
),
total_invoices as (
    select count(distinct InvoiceID) as InvoiceCount
    from #practice_sales_enriched
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
```

## SQL Answers For 15 Stakeholder Questions

```sql
/*
Practice queries for tables uploaded to the server:
fmcg_sales.categories
fmcg_sales.cities
fmcg_sales.countries
fmcg_sales.customers
fmcg_sales.employees
fmcg_sales.products
fmcg_sales.sales

Snapshot window: January 1, 2018 through April 30, 2018.
Revenue is recalculated because sales.TotalPrice is not reliable:
NetRevenue = Quantity * Price * (1 - Discount)
*/

declare @snapshot_start date = '2018-01-01';
declare @snapshot_end_exclusive date = '2018-05-01';
declare @snapshot_end date = dateadd(day, -1, @snapshot_end_exclusive);

drop table if exists #sales_enriched;

select
    s.sales_id as SalesID,
    s.transaction_number as InvoiceID,
    s.sales_date as SalesDate,
    s.product_id as ProductID,
    p.product_name as ProductName,
    p.category_id as CategoryID,
    c.category_name as CategoryName,
    s.customer_id as CustomerID,
    s.salesperson_id as EmployeeID,
    concat(e.first_name, ' ', e.last_name) as EmployeeName,
    cast(s.quantity as decimal(18, 2)) as Quantity,
    cast(p.price as decimal(18, 4)) as ProductPrice,
    cast(coalesce(s.discount, 0) as decimal(9, 4)) as DiscountRate,
    cast(s.quantity as decimal(18, 2))
        * cast(p.price as decimal(18, 4))
        * (1 - cast(coalesce(s.discount, 0) as decimal(9, 4))) as NetRevenue
into #sales_enriched
from fmcg_sales.sales s
left join fmcg_sales.products p on s.product_id = p.product_id
left join fmcg_sales.categories c on p.category_id = c.category_id
left join fmcg_sales.employees e on s.salesperson_id = e.employee_id
where s.sales_date >= @snapshot_start
    and s.sales_date < @snapshot_end_exclusive;

-- Q1. Total net revenue across the four-month snapshot.
select
    cast(sum(NetRevenue) as decimal(18, 2)) as TotalNetRevenueUSD
from #sales_enriched;

-- Q2. Product categories and SKU count, sorted alphabetically.
select
    c.category_name as CategoryName,
    count(p.product_id) as ProductCount
from fmcg_sales.categories c
left join fmcg_sales.products p on c.category_id = p.category_id
group by c.category_name
order by c.category_name;

-- Q3. Top 10 cities with the largest customer base.
select top (10)
    ci.city_name as CityName,
    co.country_name as CountryName,
    count(distinct cu.customer_id) as CustomerCount
from fmcg_sales.customers cu
inner join fmcg_sales.cities ci on cu.city_id = ci.city_id
inner join fmcg_sales.countries co on ci.country_id = co.country_id
group by ci.city_name, co.country_name
order by CustomerCount desc, co.country_name, ci.city_name;

-- Q4. Cashier headcount by gender.
select
    gender as Gender,
    count(*) as EmployeeCount
from fmcg_sales.employees
group by gender
order by gender;

-- Q5. Highest-revenue month in the four-month snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from #sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select top (1)
    concat(datename(month, MonthStart), ' ', year(MonthStart)) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD
from monthly_revenue
order by NetRevenue desc, MonthStart;

-- Q6. Top 5 best-selling products within each category by units sold.
;with product_units as (
    select
        CategoryName,
        ProductName,
        sum(Quantity) as TotalUnitsSold
    from #sales_enriched
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

-- Q7. Average order value at invoice level, not sales-line level.
;with invoice_revenue as (
    select
        InvoiceID,
        sum(NetRevenue) as InvoiceRevenue
    from #sales_enriched
    group by InvoiceID
)
select
    cast(avg(InvoiceRevenue) as decimal(18, 2)) as AverageOrderValueUSD
from invoice_revenue;

-- Q8. Repeat customers versus one-time buyers within the snapshot.
;with customer_invoice_counts as (
    select
        CustomerID,
        count(distinct InvoiceID) as InvoiceCount
    from #sales_enriched
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

-- Q9. Average cashier working days by gender as of April 30, 2018.
select
    gender as Gender,
    cast(avg(cast(datediff(day, cast(hire_date as date), @snapshot_end) as decimal(18, 2))) as decimal(18, 2)) as AverageWorkingDays
from fmcg_sales.employees
where hire_date is not null
group by gender
order by gender;

-- Q10. Catalog SKUs with no sales lines in the four-month snapshot.
;with sold_products as (
    select distinct ProductID
    from #sales_enriched
)
select
    p.product_id as SKU,
    p.product_name as ProductName,
    c.category_name as CategoryName,
    cast(p.price as decimal(18, 2)) as ListPriceUSD
from fmcg_sales.products p
left join fmcg_sales.categories c on p.category_id = c.category_id
left join sold_products sp on p.product_id = sp.ProductID
where sp.ProductID is null
order by c.category_name, p.product_name;

-- Q11. Monthly revenue and cumulative revenue from the start of the snapshot.
;with monthly_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        sum(NetRevenue) as NetRevenue
    from #sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1)
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    cast(NetRevenue as decimal(18, 2)) as MonthlyRevenueUSD,
    cast(sum(NetRevenue) over (order by MonthStart rows unbounded preceding) as decimal(18, 2)) as CumulativeRevenueUSD
from monthly_revenue
order by MonthStart;

-- Q12. Customer spend quartiles for CRM segmentation.
;with customer_spend as (
    select
        CustomerID,
        sum(NetRevenue) as TotalSpend
    from #sales_enriched
    group by CustomerID
),
ranked_customers as (
    select
        CustomerID,
        TotalSpend,
        ntile(4) over (order by TotalSpend desc, CustomerID) as SpendQuartile
    from customer_spend
),
quartile_rollup as (
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
from quartile_rollup
order by SpendQuartile;

-- Q13. Monthly category revenue share for stacked-bar reporting.
;with monthly_category_revenue as (
    select
        datefromparts(year(SalesDate), month(SalesDate), 1) as MonthStart,
        CategoryName,
        sum(NetRevenue) as NetRevenue
    from #sales_enriched
    group by datefromparts(year(SalesDate), month(SalesDate), 1), CategoryName
)
select
    convert(char(7), MonthStart, 120) as SalesMonth,
    CategoryName,
    cast(NetRevenue as decimal(18, 2)) as NetRevenueUSD,
    cast(100.0 * NetRevenue / nullif(sum(NetRevenue) over (partition by MonthStart), 0) as decimal(6, 2)) as MonthlyRevenueSharePct
from monthly_category_revenue
order by MonthStart, CategoryName;

-- Q14. Best rolling 30-day revenue window achieved by each employee.
;with date_spine as (
    select @snapshot_start as SalesDay
    union all
    select dateadd(day, 1, SalesDay)
    from date_spine
    where SalesDay < @snapshot_end
),
employee_days as (
    select
        e.employee_id as EmployeeID,
        concat(e.first_name, ' ', e.last_name) as EmployeeName,
        d.SalesDay
    from fmcg_sales.employees e
    cross join date_spine d
),
daily_employee_revenue as (
    select
        EmployeeID,
        cast(SalesDate as date) as SalesDay,
        sum(NetRevenue) as DailyRevenue
    from #sales_enriched
    group by EmployeeID, cast(SalesDate as date)
),
rolling_windows as (
    select
        ed.EmployeeID,
        ed.EmployeeName,
        ed.SalesDay as WindowStartDate,
        sum(coalesce(der.DailyRevenue, 0)) as Rolling30DayRevenue
    from employee_days ed
    left join daily_employee_revenue der
        on ed.EmployeeID = der.EmployeeID
        and der.SalesDay >= ed.SalesDay
        and der.SalesDay < dateadd(day, 30, ed.SalesDay)
    group by ed.EmployeeID, ed.EmployeeName, ed.SalesDay
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

-- Q15. Top 20 same-invoice product pairs for bundle planning.
;with invoice_products as (
    select distinct
        InvoiceID,
        ProductID,
        ProductName
    from #sales_enriched
),
eligible_invoices as (
    select InvoiceID
    from invoice_products
    group by InvoiceID
    having count(distinct ProductID) >= 2
),
total_invoices as (
    select count(distinct InvoiceID) as InvoiceCount
    from #sales_enriched
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
```
