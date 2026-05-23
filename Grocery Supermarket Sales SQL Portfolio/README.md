# Grocery Supermarket Sales SQL Portfolio

End-to-end SQL portfolio project for a multinational FMCG supermarket sales dataset.

This project focuses on SQL Server analytics: schema design, CSV loading, data-quality checks, business marts, window functions, ranking, segmentation, and validation queries. The output supports a Power BI dashboard, but the core portfolio proof is SQL.

## Project Summary

The source data contains seven relational CSV files:

- `categories.csv`
- `cities.csv`
- `countries.csv`
- `customers.csv`
- `employees.csv`
- `products.csv`
- `sales.csv`

The sales file contains 6,758,125 line-level records. The portfolio models the data into a retail analytics layer covering revenue, products, customers, employees, and geography.

## Key Metrics

| Metric | Value |
| --- | ---: |
| Sales rows | 6,758,125 |
| Products | 452 |
| Customers | 98,759 |
| Employees | 23 |
| Cities | 96 |
| Countries | 206 |
| Categories | 11 |
| Calculated net revenue | 4,332,445,646.06 |
| Gross revenue estimate | 4,466,259,165.52 |
| Units sold | 87,882,708 |
| Invoice count | 6,758,125 |
| Average order value | 641.07 |
| Average basket size | 13.0040 |

## Important Data Quality Finding

`sales.TotalPrice` is zero for every processed sales row. Revenue is therefore calculated as:

```text
NetRevenue = Quantity * products.Price * (1 - Discount)
```

This is a documented source-data quality issue and is handled consistently across SQL, validation notes, and BI-ready exports.

## Skills Demonstrated

- SQL Server schema design
- Bulk CSV loading pattern
- Raw-to-mart data modeling
- CTEs and layered SQL transformations
- Joins across fact and dimension tables
- Window functions for ranking and month-over-month analysis
- Customer segmentation
- Employee performance analytics
- Geographic market analysis
- Data-quality checks and reconciliation queries
- Power BI-ready SQL mart design

## Repository Structure

```text
Grocery Supermarket Sales SQL Portfolio/
|-- README.md
|-- source-data/
|   |-- categories.csv
|   |-- cities.csv
|   |-- countries.csv
|   |-- customers.csv
|   |-- employees.csv
|   |-- products.csv
|   `-- sales.csv
|-- docs/
|   |-- data-dictionary.md
|   |-- engine-translation-notes.md
|   |-- sql-analysis-guide.md
|   |-- validation-report.md
|   `-- assets/
|       `-- exports/
|-- sql/
|   |-- 00-create-database-and-schema.sql
|   |-- 01-load-raw-csv-bulk-insert.sql
|   |-- 02-analytics-views.sql
|   |-- 03-business-analysis-queries.sql
|   `-- 04-validation-queries.sql
`-- tools/
    `-- README.md
```

## How To Reproduce

1. Open SQL Server Management Studio or Azure Data Studio.
2. Run `sql/00-create-database-and-schema.sql`.
3. Edit `@dataset_root` in `sql/01-load-raw-csv-bulk-insert.sql` to the absolute path of this project's `source-data/` folder.
4. Run `sql/01-load-raw-csv-bulk-insert.sql`.
5. Run `sql/02-analytics-views.sql`.
6. Run `sql/04-validation-queries.sql`.
7. Run `sql/03-business-analysis-queries.sql` to inspect the business outputs.

Source dataset location inside this project:

```text
source-data/
```

SQL Server `BULK INSERT` requires an absolute filesystem path, so paste the full local path to `source-data/` into `@dataset_root` before loading.

## Analytical Questions

1. What is calculated net revenue after discount?
2. Which categories drive month-over-month revenue?
3. Which products are top and bottom performers?
4. Which product classes contribute the most revenue and units?
5. How do customer value, invoice count, AOV, and basket size vary?
6. Which employees lead or lag in revenue and invoice volume?
7. Which cities and countries are strongest markets?
8. Which data quality issues affect final reporting?

## SQL Outputs

The analytics views create these reusable marts:

- `mart.vw_executive_kpis`
- `mart.vw_monthly_category_revenue`
- `mart.vw_product_performance`
- `mart.vw_customer_segments`
- `mart.vw_employee_performance`
- `mart.vw_geo_market`
- `mart.vw_class_performance`

The `source-data/` folder contains the seven source CSV files. The `docs/assets/exports/` folder contains cooked CSV equivalents generated during the Power BI preparation workflow, so portfolio reviewers can inspect expected outputs without loading the full 517 MB source sales file.

## Power BI Handoff

Power BI should connect to either:

- the SQL Server mart views, or
- the cooked CSV exports in `docs/assets/exports/`.

The SQL mart view names map directly to the dashboard pages: executive overview, product and inventory, customer behavior, workforce performance, geography, and data quality.

## Limitations

- Source `TotalPrice` is unusable as revenue because it is zero in all rows.
- 67,526 rows have blank `SalesDate`; the SQL views group them under `Unknown`.
- Customer repeat logic uses `TransactionNumber` as invoice key.
- The dataset appears synthetic and should be used for portfolio demonstration, not real commercial decisions.

## Future Improvements

- Add SQL Server Agent or dbt-style orchestration.
- Add indexed materialized tables for large production refreshes.
- Add a Power BI `.pbix` built directly from SQL Server views.
- Add BigQuery and MySQL versions of the mart views.
