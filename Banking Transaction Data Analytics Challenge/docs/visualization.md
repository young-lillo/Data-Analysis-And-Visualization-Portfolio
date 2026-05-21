# Visualization

## Status

Power BI report documentation and published dashboard available.

## Public Dashboard

[View the published Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNjgyMTFlMGUtZGI1YS00NGMyLTk0ZmEtODUxODRlMzE2NWYzIiwidCI6IjM3MGZiM2I4LTMzMDYtNDg5MC05MDYzLWNjMDhiZTc4ODI1NyIsImMiOjEwfQ%3D%3D)

## Tool

- Visualization tool: Power BI
- Deploy target: Power BI Service public report plus local Power BI Desktop handoff
- Primary fact table: `docs/assets/exports/fact-banking-transactions-star.csv`
- Supporting prepared table: `docs/assets/exports/banking-transactions-prepared-usd.csv`
- Reporting currency: USD

## Data Model

Supporting flat-table assets:

- `FactBankingTransactions`: prepared transaction fact table.
- `DimCalendar`: `dim-calendar.csv`, related to `FactBankingTransactions[TransactionDate]`.
- `CurrencyRates`: `currency-rates-to-usd.csv`, audit table for historical FX rates.

Primary portfolio star-schema model:

- `FactBankingTransactions`: `fact-banking-transactions-star.csv`.
- `DimDate`: `dim-date-star.csv`.
- `DimCustomer`
- `DimCustomerProfile`
- `DimProduct`
- `DimBranch`
- `DimChannel`
- `DimTransactionType`
- `DimRecommendedOffer`
- `DimCurrency`
- `DimCurrencyRate`
- `DimTransactionValueBand`

Relationship rules:

- Use one-to-many relationships from each dimension to `FactBankingTransactions`.
- Use single filter direction from dimension to fact.
- Mark `DimDate[Date]` as the date table.
- Use `DimCustomerProfile` for customer segment, credit score band, and income band visuals.
- Use `DimCustomer` for customer-level tables and customer counts only.

## Report Pages

1. Executive Overview: KPI cards, monthly trend, top revenue drivers, and key recommendation callouts.
2. Customer Segments: segment activity, product preference, income and score bands, fees per customer.
3. Transaction Behavior: transaction type count versus value, product mix, and channel patterns.
4. Revenue And Friction: fees, late-payment amounts, friction flags, and fee burden.
5. Branch And Geography: city map, branch ranking, and underperforming locations.
6. Trends And Offers: seasonal patterns, recommended offer distribution, and offer-to-behavior alignment.

## Visual Rules

- Monetary visuals use USD-normalized measures by default.
- Keep original currency fields available for audit and drillthrough.
- Use slicers for date, segment, product category, branch city, channel, and currency.
- Use tooltips for original amount, rate, and USD amount where currency conversion matters.

## Supporting Docs

- `docs/power-query-transformations.md`
- `docs/dax-measures.md`
- `docs/assets/exports/analysis-summary.md`

## Unresolved Questions

- None.
