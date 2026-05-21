# Power BI Report Build Guide

## Build Order

1. Import cooked CSV outputs from `docs/assets/exports/`.
2. Rename `banking-transactions-prepared-usd` to `FactBankingTransactions`.
3. Rename `dim-calendar` to `DimCalendar`.
4. Rename `currency-rates-to-usd` to `CurrencyRates`.
5. Set data types using `docs/power-query-transformations.md`.
6. Create relationship `DimCalendar[Date]` to `FactBankingTransactions[TransactionDate]`.
7. Add measures from `docs/dax-measures.md`.
8. Build pages from `docs/visualization.md`.
9. Save the first deliverable as a `.pbix` file.
10. Export screenshots or PDF to `docs/assets/screenshots/` or `docs/assets/exports/`.

## Page 1: Executive Overview

- KPI cards: transactions, distinct customers, total amount USD, total fees USD, fee rate, late-payment USD.
- Line chart: `YearMonth` by `Total Amount USD` and `Total Fees USD`.
- Bar chart: `TransactionType` by `Transactions`.
- Bar chart: `CustomerSegment` by `Total Amount USD`.
- Slicers: date, customer segment, channel, product category, city.

## Page 2: Customer Segments

- Matrix: `CustomerSegment` by `ProductCategory`, values `Transactions` and `Total Amount USD`.
- Stacked bar: `CreditScoreBand` by `CustomerSegment`.
- Scatter: `Average Monthly Income` and `Average Customer Score`, sized by `Total Fees USD`.
- Table: segment rankings by `Fees Per Customer USD`.

## Page 3: Transaction Behavior

- Combo chart: `TransactionType` with count and total amount USD.
- Heatmap matrix: `Channel` by `TransactionType`.
- Treemap: `ProductCategory` and `ProductSubcategory` by `Total Amount USD`.
- Drillthrough table for transaction-level audit.

## Page 4: Revenue And Friction

- KPI cards: credit-card fees USD, insurance fees USD, late-payment USD, fee transaction share, high-fee burden share.
- Bar chart: fee types by USD amount.
- Table: high-fee burden candidates from `HighFeeBurdenFlag`.
- Histogram or binned bar: `FeeRate`.

## Page 5: Branch And Geography

- Map: `BranchLat`, `BranchLong`, size by `Total Amount USD`, color by `Total Fees USD`.
- Bar chart: `BranchCity` by `Transactions`.
- Bar chart: `BranchCity` by `Total Amount USD`.
- Table: city rank, customers, fees, fee rate.

## Page 6: Trends And Offers

- Line chart: monthly transaction count and fee revenue.
- Column chart: `Season` by `Total Amount USD`.
- Matrix: `CustomerSegment` by `RecommendedOffer`.
- Bar chart: recommended offer by fee burden and score band.

## Design Notes

- Use USD labels everywhere a monetary value is shown.
- Keep original currency and original amount fields on tooltip or audit tables only.
- Use restrained banking colors: navy, teal, slate, white, and amber for risk/friction.
- Avoid treating synthetic high-fee flags as credit decisions.

## Unresolved Questions

- Should the `.pbix` later be moved to Power BI Service refresh after the desktop report is built?
