# Validation Report

## Status

Portfolio package created from the cooked FMCG project outputs.

## Known Cooked Totals

| Metric | Value |
| --- | ---: |
| Sales rows | 6,758,125 |
| Categories | 11 |
| Cities | 96 |
| Countries | 206 |
| Customers | 98,759 |
| Employees | 23 |
| Products | 452 |
| Net revenue | 4,332,445,646.06 |
| Gross revenue estimate | 4,466,259,165.52 |
| Units sold | 87,882,708 |
| Invoice count | 6,758,125 |
| Average order value | 641.07 |
| Average basket size | 13.0040 |

## Data Quality Findings

- `sales.TotalPrice` is zero in all 6,758,125 processed sales rows.
- Revenue is calculated as `Quantity * products.Price * (1 - Discount)`.
- 67,526 sales rows have blank `SalesDate`.
- Blank date rows should be grouped as `Unknown` or excluded from timeline charts.
- `TransactionNumber` is used as invoice key.

## SQL Validation

Run:

```sql
sql/04-validation-queries.sql
```

Expected checks:

- row count checks match the source counts
- no duplicate `SalesID`
- source-to-mart revenue reconciliation returns zero difference
- executive net revenue rounds to `4,332,445,646.06`

Local note: `sqlcmd` was not available in the Codex environment during package creation, so SQL Server execution should be performed in SQL Server Management Studio or Azure Data Studio.

## Artifact Validation

The portfolio includes the cooked mart CSV outputs under:

```text
docs/assets/exports/
```

These exports are included for reviewer convenience and match the Power BI preparation workflow.

Unresolved questions:

- Should `Unknown` sales month rows be excluded from the final dashboard trend pages?
