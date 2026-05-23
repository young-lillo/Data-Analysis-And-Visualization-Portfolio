# SQL Analysis Guide

## Goal

Show a reviewer that the project is SQL-first: raw data is loaded into SQL Server, modeled into reusable marts, validated, and queried for business insight.

## Script Order

1. `00-create-database-and-schema.sql`
2. `01-load-raw-csv-bulk-insert.sql`
3. `02-analytics-views.sql`
4. `04-validation-queries.sql`
5. `03-business-analysis-queries.sql`

## What Each Script Demonstrates

### Schema Setup

`00-create-database-and-schema.sql` creates:

- database
- `raw`, `mart`, and `audit` schemas
- typed raw tables
- useful indexes on join/filter fields
- idempotent guards for repeatable setup runs

### Loading

`01-load-raw-csv-bulk-insert.sql` demonstrates SQL Server `BULK INSERT` from seven CSV files.
The loader quotes schema/table identifiers and escapes file paths before executing dynamic SQL.
It also disables and rebuilds `raw.sales` nonclustered indexes around the large sales load.

Update this variable before running:

```sql
declare @dataset_root nvarchar(4000) =
    N'<absolute-path-to-this-project>\source-data';
```

### Mart Views

`02-analytics-views.sql` builds the analytical layer.

Important patterns:

- multi-table joins
- `case` expressions for data-quality-aware revenue
- single-pass sales date parsing in the enriched sales view
- CTEs
- `dense_rank`
- `lag`
- windowed contribution share
- safe division with `nullif`

### Business Questions

`03-business-analysis-queries.sql` answers:

- executive KPI summary
- category month-over-month performance
- top and bottom product ranking
- high-volume low-yield products
- customer segments
- employee performance
- geographic market ranking

### Validation

`04-validation-queries.sql` checks:

- row counts
- duplicate primary keys
- missing foreign keys
- zero `TotalPrice`
- blank `SalesDate`
- mart reconciliation

## Expected Validation Targets

| Check | Expected |
| --- | ---: |
| `raw.sales` rows | 6,758,125 |
| Net revenue | 4,332,445,646.06 |
| Gross revenue estimate | 4,466,259,165.52 |
| Units sold | 87,882,708 |
| Customers with sales | 98,759 |
| Blank sales date rows | 67,526 |
| Zero total price rows | 6,758,125 |

## Portfolio Talking Points

- I do not trust source revenue blindly; I validate it against quantity, price, and discount.
- I separate raw loading from mart views so business logic is reviewable.
- I use window functions to support month-over-month and contribution analysis.
- I provide validation queries so dashboards can be reconciled to SQL totals.
- I design SQL marts that map directly to BI pages.

## Reviewer Flow

For a quick review, open:

1. `README.md`
2. `sql/02-analytics-views.sql`
3. `sql/03-business-analysis-queries.sql`
4. `docs/validation-report.md`
