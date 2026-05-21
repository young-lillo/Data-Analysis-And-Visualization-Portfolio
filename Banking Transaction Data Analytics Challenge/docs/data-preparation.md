# Data Preparation

## Status

Cooked for Power BI.

## Source

- Workbook: `Banking_Transactional_Dataset.xlsx`
- Main sheet: `Banking Data`
- Data dictionary sheet: `Data Dictionary`
- Source rows: 20,000
- Source fields: 19
- Reporting currency: USD

## Prepared Data Contract

Primary fact table:

- `docs/assets/exports/banking-transactions-prepared-usd.csv`

Supporting tables:

- `docs/assets/exports/currency-rates-to-usd.csv`
- `docs/assets/exports/dim-calendar.csv`
- `docs/assets/exports/data-dictionary.csv`

Star-schema upgrade outputs:

- `docs/assets/exports/fact-banking-transactions-star.csv`
- `docs/assets/exports/dim-date-star.csv`
- `docs/assets/exports/dim-customer.csv`
- `docs/assets/exports/dim-customer-profile.csv`
- `docs/assets/exports/dim-product.csv`
- `docs/assets/exports/dim-branch.csv`
- `docs/assets/exports/dim-channel.csv`
- `docs/assets/exports/dim-transaction-type.csv`
- `docs/assets/exports/dim-recommended-offer.csv`
- `docs/assets/exports/dim-currency.csv`
- `docs/assets/exports/dim-currency-rate.csv`
- `docs/assets/exports/dim-transaction-value-band.csv`
- `docs/assets/exports/star-schema-validation.json`

Summary outputs:

- `docs/assets/exports/summary-by-customer-segment.csv`
- `docs/assets/exports/summary-by-transaction-type.csv`
- `docs/assets/exports/summary-by-product-category.csv`
- `docs/assets/exports/summary-by-branch-city.csv`
- `docs/assets/exports/summary-by-channel.csv`
- `docs/assets/exports/summary-by-month.csv`
- `docs/assets/exports/summary-by-offer.csv`
- `docs/assets/exports/summary-offer-by-segment.csv`
- `docs/assets/exports/high-fee-burden-candidates.csv`
- `docs/assets/exports/profile-kpis.json`

## Transformations Applied

- Parsed `TransactionDate` as date.
- Preserved original `Currency` and source monetary fields.
- Added `RateToUSD`.
- Added USD-normalized fields: `AmountUSD`, `CreditCardFeesUSD`, `InsuranceFeesUSD`, `LatePaymentAmountUSD`, `TotalFeesUSD`.
- Added original-value audit fields: `AmountOriginal`, `CreditCardFeesOriginal`, `InsuranceFeesOriginal`, `LatePaymentAmountOriginal`, `TotalFeesOriginal`.
- Added calendar fields: `Year`, `Quarter`, `MonthNumber`, `MonthName`, `YearMonth`, `MonthStart`, `Season`.
- Added analytical fields: `FeeRate`, `HasFeeFriction`, `HasLatePayment`, `CreditScoreBand`, `MonthlyIncomeBand`, `TransactionValueBandUSD`, `FeeBurdenZScore`, `HighFeeBurdenFlag`.
- Added star-schema foreign keys for Power BI modeling: `DateKey`, `ProductKey`, `BranchKey`, `ChannelKey`, `TransactionTypeKey`, `OfferKey`, `CurrencyKey`, `CurrencyRateKey`, `CustomerProfileKey`, and `TransactionValueBandKey`.
- Created customer, product, branch, channel, transaction-type, offer, currency, currency-rate, customer-profile, transaction-value-band, and date dimensions.

## FX Method

- EUR values use daily historical EUR/USD rates from Frankfurter API v2 with `provider=ECB`.
- USD values use `RateToUSD = 1.00`.
- Weekends and other non-publication dates use the previous available published EUR/USD rate.
- `FXRateDate` records the published rate date actually used for each fact row.
- Raw fetched EUR/USD rates are stored in `docs/assets/exports/frankfurter-eur-usd-rates-raw.json`.

## Validation

- Row count reconciles to 20,000.
- Duplicate `TransactionID` count is 0.
- Missing values across source fields are 0.
- Source currencies are EUR and USD.
- USD totals reconcile to `RateToUSD` conversion logic.
- EUR/USD rates used range from 1.0198 to 1.1476.
- Star-schema fact row count reconciles to 20,000.
- Star-schema missing foreign key count is 0 across all model relationships.
- Star-schema totals reconcile to total amount USD `$107,954,758.28` and total fee revenue USD `$681,084.03`.

## Modeling Note

`CustomerID` is not a stable profile grain in the source data. Many customers appear with more than one segment, income, or score value. The dimensional model therefore keeps:

- `DimCustomer` for customer identity and customer-level rollups.
- `DimCustomerProfile` for transaction-level segment, score-band, and income-band filtering.

## Unresolved Questions

- Should final Power BI refresh use the prepared CSVs or rebuild transformations directly from the Excel workbook after the `.pbix` is built?
