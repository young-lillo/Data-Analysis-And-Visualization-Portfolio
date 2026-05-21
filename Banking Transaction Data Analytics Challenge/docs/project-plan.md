# Project Plan

## Confirmed Decisions

- Framework: CRISP-DM
- Goal tier: Advanced
- Visualization tool: Power BI
- Deploy target: Power BI

## Intake Summary

- Context: Banking Data Analyst portfolio challenge for internal transaction analytics.
- Dataset: `Banking_Transactional_Dataset.xlsx`
- Source workbook: `Banking_Transactional_Dataset.xlsx`
- Main sheet: `Banking Data`, 20,000 rows, 19 columns
- Dictionary sheet: `Data Dictionary`, 19 column definitions
- Reporting currency: USD
- User goals: Segment customers, explain transaction behavior, quantify fee revenue, compare branch/channel performance, evaluate offer alignment, and deliver strategic recommendations.

## Dataset Surface

- Customer grain: `CustomerID`
- Transaction grain: `TransactionID`
- Date field: `TransactionDate`
- Core measures: `Amount`, `CreditCardFees`, `InsuranceFees`, `LatePaymentAmount`, `MonthlyIncome`, `CustomerScore`
- Business dimensions: `TransactionType`, `ProductCategory`, `ProductSubcategory`, `BranchCity`, `Channel`, `Currency`, `CustomerSegment`, `RecommendedOffer`
- Geo fields: `BranchLat`, `BranchLong`

## Working Interpretation

This is an insight-first banking analytics case. The final Power BI report should behave like a stakeholder-facing portfolio deliverable: concise executive KPIs first, drillable segment and product analysis second, then risk, revenue, geography, and offer-alignment evidence behind the recommendations.

## CRISP-DM Plan

1. Business Understanding
   - Define the bank's priority questions around activity, profitability, channel usage, risk, and retention.
   - Translate the four analytical phases into report pages and measurable KPIs.

2. Data Understanding
   - Profile transaction counts, date range, currencies, missing values, duplicate IDs, and outliers.
   - Validate whether `Amount` should be interpreted as transaction value for every `TransactionType`.
   - Check whether fee columns are sparse, mutually exclusive, or combinable into total fee revenue.

3. Data Preparation
   - Import both workbook sheets into Power BI.
   - Create a cleaned fact table from `Banking Data`.
   - Add calendar fields: year, quarter, month, month sort key, season.
   - Convert all monetary reporting measures to USD while preserving original currency and original amount fields.
   - Add an auditable FX-rate reference table with `Date`, `Currency`, `RateToUSD`, `FXRateDate`, and `RateSource`.
   - Add derived measures or columns for total fees, fee rate, income band validation, score band, transaction value band, and friction flag.
   - Consider separating dimensions for customers, products, branches, channels, offers, and calendar if the model becomes dense.

4. Modeling
   - Build DAX measures for transaction count, distinct customers, total amount, average transaction amount, total fees, fee per transaction, fee per customer, late-payment exposure, and offer mix.
   - Add Advanced tier analysis: anomaly flags for unusual fee burden, monthly trend decomposition, segment/channel driver comparison, and branch performance quartiles.
   - Optional Python/SQL export path: use Python for profiling and anomaly scoring if Power BI-only modeling becomes too constrained.

5. Evaluation
   - Check every page against a business question.
   - Validate totals against source row counts and fee sums.
   - Review whether high-fee groups are genuinely high-risk or simply high-volume.

6. Deployment
   - Deliver a `.pbix` report plus exported screenshots/PDF if needed.
   - Store Power Query notes, DAX measure definitions, screenshots, and export artifacts under `docs/assets/`.
   - Deliver `.pbix` first. Treat Power BI Service publishing as a later optional step after workspace access and refresh settings are confirmed.

## Goal Ladder

### Basic

- Clean the workbook and create trusted KPI cards.
- Show transaction count, total amount, total fees, top products, top cities, and channel mix.

### Pro

- Explain differences by customer segment, product, city, branch channel, and offer.
- Compare transaction volume versus transaction value.
- Identify fee revenue drivers and customer groups with high fee burden.

### Advanced

- Detect unusual fee, late-payment, or transaction-value patterns.
- Analyze seasonal peaks and troughs by segment and channel.
- Score branch/city performance using value, activity, and fee mix.
- Evaluate whether recommended offers align with actual customer behavior.
- Produce a strategic roadmap for personalization, risk mitigation, channel optimization, and retention.

## Power BI Report Blueprint

- Executive Overview: KPI cards, monthly transaction/fee trend, top revenue drivers, key recommendation callouts.
- Customer Segments: segment activity, product preference, income/score bands, fees per customer.
- Transaction Behavior: transaction type count vs amount, product mix, channel patterns.
- Revenue and Friction: credit-card fees, insurance fees, late-payment amounts, friction flags, fee burden.
- Branch and Geography: city map, branch/city ranking, underperforming locations.
- Trends and Offers: month/season patterns, recommended offer distribution, offer-to-behavior alignment.

## Expected Technical Depth

- Power Query: required for type cleanup, USD normalization, date enrichment, fee fields, score bands, and reusable transformations.
- DAX: required for reusable USD KPIs, ratios, ranking, quartiles, trend comparisons, and offer-alignment measures.
- SQL: optional unless the workbook is loaded into a database first.
- Python: useful for profiling, anomaly detection, and reproducible validation exports.

## Success Criteria

- Row count reconciles to 20,000 transactions.
- All KPI totals reconcile to the source workbook.
- USD-normalized amount and fee totals reconcile to documented FX conversion logic.
- Each analytical phase has at least one dedicated report view or section.
- Advanced analysis includes anomaly, trend, or scenario-style insight beyond descriptive charts.
- Recommendations are linked to visible evidence in the report.

## Risks And Assumptions

- Assumes the dataset is synthetic and safe for portfolio use.
- Assumes `CustomerSegment` is provided, not inferred.
- Assumes `RecommendedOffer` represents bank-generated recommendations, not accepted offers.
- Confirmed reporting currency is USD.
- FX conversion uses daily historical EUR/USD rates from Frankfurter API v2 with `provider=ECB`; weekends and non-publication dates use the previous available published rate.
- Latitude/longitude appear city-level, so geography should be interpreted as branch-city analysis, not exact branch-level routing.

## Recommended Next Workflow

Run `$dv-cook --slug banking-transaction-data-analytics-challenge --brief "Build the Power BI-ready data preparation, analysis notes, DAX plan, and dashboard documentation from the approved project plan."`

## Unresolved Questions

- Should the `.pbix` later be moved to Power BI Service refresh after the desktop report is built?
