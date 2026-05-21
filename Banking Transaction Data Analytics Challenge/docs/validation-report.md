# Validation Report

## Status

Passed for cooked project artifacts.

## Checks

- Project docs path exists.
- Prepared fact CSV exists.
- Currency rates CSV exists.
- Calendar CSV exists.
- Summary CSVs exist.
- DAX measure documentation exists.
- Power Query documentation exists.
- Power BI report build guide exists.
- Star-schema fact and dimension CSVs exist.

## Data Checks

- Source row count: 20,000
- Prepared row count: 20,000
- Distinct customers: 8,025
- Duplicate `TransactionID` count: 0
- Missing source values: 0 across all 19 source fields
- Source currencies: EUR, USD
- Reporting currency: USD
- FX method: daily historical EUR/USD from Frankfurter API v2 with `provider=ECB`; previous available published rate used for non-publication dates; native USD = 1.00
- EUR/USD rate range used: 1.0198 to 1.1476

## Cooked KPI Snapshot

- Total amount USD: $107,954,758.28
- Total fee revenue USD: $681,084.03
- Credit-card fees USD: $111,575.13
- Insurance fees USD: $213,261.25
- Late-payment USD: $356,247.65
- Fee transactions: 10,106
- High-fee burden candidates: 1,371

## Star Schema Validation

- Star fact rows: 20,000
- Duplicate `TransactionID` count: 0
- Missing foreign keys: 0
- `DimCustomer` rows: 8,025
- `DimCustomerProfile` rows: 20
- Customers with profile changes detected: 5,848
- Star-schema total amount USD: $107,954,758.28
- Star-schema total fee revenue USD: $681,084.03

Customer profile changes are expected in this synthetic dataset. Use `DimCustomerProfile` for segment, score-band, and income-band filtering, and use `DimCustomer` for customer identity and customer-level tables.

## Tool-Aware Deploy Check

Power BI does not expose a kit-managed local web server like Evidence, Metabase, or Grafana. Local validation is therefore file-based: open the cooked CSVs and docs in Power BI Desktop, then build or refresh the `.pbix` report.

## Unresolved Questions

- Should the `.pbix` later be moved to Power BI Service refresh after the desktop report is built?
