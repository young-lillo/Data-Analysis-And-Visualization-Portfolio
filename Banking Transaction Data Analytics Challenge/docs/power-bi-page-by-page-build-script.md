# Power BI Page-By-Page Build Script

## Purpose

Use this as the hands-on build script for the star-schema Power BI model in `banking-transaction-analytics-star-schema.pbix`.

## Pre-Build Checklist

1. Open `docs/assets/exports/banking-transaction-analytics-star-schema.pbix`.
2. Confirm these tables are loaded:
   - `FactBankingTransactions`
   - `DimDate`
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
3. Confirm no dimension table still has generic headers like `Column1` or `Column2`.
4. Confirm these relationships are active, one-to-many, single direction from dimension to fact:
   - `DimDate[DateKey]` -> `FactBankingTransactions[DateKey]`
   - `DimCustomer[CustomerID]` -> `FactBankingTransactions[CustomerID]`
   - `DimCustomerProfile[CustomerProfileKey]` -> `FactBankingTransactions[CustomerProfileKey]`
   - `DimProduct[ProductKey]` -> `FactBankingTransactions[ProductKey]`
   - `DimBranch[BranchKey]` -> `FactBankingTransactions[BranchKey]`
   - `DimChannel[ChannelKey]` -> `FactBankingTransactions[ChannelKey]`
   - `DimTransactionType[TransactionTypeKey]` -> `FactBankingTransactions[TransactionTypeKey]`
   - `DimRecommendedOffer[OfferKey]` -> `FactBankingTransactions[OfferKey]`
   - `DimCurrency[CurrencyKey]` -> `FactBankingTransactions[CurrencyKey]`
   - `DimCurrencyRate[CurrencyRateKey]` -> `FactBankingTransactions[CurrencyRateKey]`
   - `DimTransactionValueBand[TransactionValueBandKey]` -> `FactBankingTransactions[TransactionValueBandKey]`
5. Mark `DimDate` as the date table using `DimDate[Date]`.
6. Confirm validation targets:
   - Transactions: 20,000
   - Distinct Customers: 8,025
   - Total Amount USD: $107,954,758.28
   - Total Fees USD: $681,084.03
   - EUR/USD rate range: 1.0198 to 1.1476

## Theme And Layout

- Canvas: 16:9.
- Canvas background: `#F6FBF7`.
- Wallpaper: `#F6FBF7`.
- Card background: `#FFFFFF` or `#F6FBF7`.
- Card border/gridline: `#D7E7DD`.
- Page title: 24 pt, bold, `#0E3B2E`.
- Section labels: 12 to 14 pt, semibold, `#0E3B2E`.
- Card labels: 10 to 11 pt.
- KPI value color: `#0E3B2E`.
- Axis, legend, and secondary text: `#1F6F54`.
- Palette:
  - Deep green: `#0E3B2E` - title, KPI values, emphasis, high friction.
  - Bank green: `#1F6F54` - main bars and primary measure series.
  - Mint green: `#5FB88A` - secondary bars, line series, positive/healthy signal.
  - Pale green: `#D7E7DD` - borders, gridlines, slicer fills, matrix low intensity.
  - Off white: `#F6FBF7` - page background.
- Use USD measures by default.
- Use original currency fields only in tooltips or audit tables.

## Visual Color Mapping

- Primary monetary value (`Total Amount USD`): `#1F6F54`.
- Fee revenue (`Total Fees USD`): `#0E3B2E`.
- Secondary/volume series (`Transactions`, `Distinct Customers`): `#5FB88A`.
- Late payment and high-fee burden: `#0E3B2E`.
- Normal borders and gridlines: `#D7E7DD`.
- Text labels and legends: `#1F6F54`.
- Backgrounds: `#F6FBF7` for page, `#FFFFFF` for cards when contrast is needed.

## Apply To Every Page

Use these formatting settings unless a visual below says otherwise:

- Page canvas background: `#F6FBF7`.
- Visual background: `#FFFFFF`, transparency 0%.
- Visual border: on, color `#D7E7DD`, rounded corners 4-6 if available.
- Visual title: `#0E3B2E`, 12-14 pt, semibold.
- Category labels and legend text: `#1F6F54`.
- Data labels: `#0E3B2E` for KPI/important values, `#1F6F54` for regular labels.
- X/Y axis labels: `#1F6F54`.
- Gridlines: `#D7E7DD`.
- Table header background: `#0E3B2E`.
- Table header text: `#F6FBF7`.
- Table values text: `#1F6F54`.
- Table alternating rows: `#FFFFFF` and `#F6FBF7`.
- Conditional formatting low-to-high scale: `#D7E7DD` -> `#5FB88A` -> `#0E3B2E`.

## Global Slicers

Create the same slicer group on every analytical page:

- `DimDate[Date]` or `DimDate[YearMonth]`
- `DimCustomerProfile[CustomerSegment]`
- `DimChannel[Channel]`
- `DimProduct[ProductCategory]`
- `DimBranch[BranchCity]`
- Optional audit slicer: `DimCurrency[Currency]`

Recommended placement:

- Left vertical slicer rail, 210 px wide.
- Use dropdown style for high-cardinality fields.
- Sync slicers across pages after all pages are built.
- Slicer background: `#F6FBF7`.
- Slicer border: `#D7E7DD`.
- Slicer header: `#0E3B2E`.
- Slicer values: `#1F6F54`.

## Star Schema Header Check

If a dimension table shows `Column1`, `Column2`, or a category value named like the column header, fix it before building visuals:

1. Go to `Home > Transform data`.
2. Select the broken dimension query.
3. Choose `Use First Row as Headers`.
4. Rename columns if needed.
5. Close and apply.

Expected dimension columns:

| Table | Required columns |
|---|---|
| `DimChannel` | `ChannelKey`, `Channel` |
| `DimCurrency` | `CurrencyKey`, `Currency` |
| `DimRecommendedOffer` | `OfferKey`, `RecommendedOffer` |
| `DimTransactionType` | `TransactionTypeKey`, `TransactionType` |
| `DimProduct` | `ProductKey`, `ProductCategory`, `ProductSubcategory` |
| `DimBranch` | `BranchKey`, `BranchCity`, `BranchLat`, `BranchLong` |
| `DimCustomerProfile` | `CustomerProfileKey`, `CustomerSegment`, `CreditScoreBand`, `MonthlyIncomeBand`, `CreditScoreBandOrder`, `MonthlyIncomeBandOrder`, `CustomerProfileLabel` |
| `DimTransactionValueBand` | `TransactionValueBandKey`, `TransactionValueBandUSD`, `TransactionValueBandOrder` |

## Measures To Create First

Recommended: create an `_Measures` table and set every measure's `Home table` to `_Measures`. Measures still calculate from `FactBankingTransactions`; `_Measures` only keeps the Fields pane clean.

Use these star-schema measures:

```DAX
Transactions =
COUNTROWS ( FactBankingTransactions )

Distinct Customers =
DISTINCTCOUNT ( FactBankingTransactions[CustomerID] )

Total Amount USD =
SUM ( FactBankingTransactions[AmountUSD] )

Average Transaction USD =
AVERAGE ( FactBankingTransactions[AmountUSD] )

Credit Card Fees USD =
SUM ( FactBankingTransactions[CreditCardFeesUSD] )

Insurance Fees USD =
SUM ( FactBankingTransactions[InsuranceFeesUSD] )

Late Payment USD =
SUM ( FactBankingTransactions[LatePaymentAmountUSD] )

Total Fees USD =
SUM ( FactBankingTransactions[TotalFeesUSD] )

Fee Rate =
DIVIDE ( [Total Fees USD], [Total Amount USD] )

Fee Transactions =
CALCULATE (
    [Transactions],
    FactBankingTransactions[HasFeeFriction] = TRUE ()
)

Fee Transaction Share =
DIVIDE ( [Fee Transactions], [Transactions] )

Late Payment Transactions =
CALCULATE (
    [Transactions],
    FactBankingTransactions[HasLatePayment] = TRUE ()
)

High Fee Burden Transactions =
CALCULATE (
    [Transactions],
    FactBankingTransactions[HighFeeBurdenFlag] = TRUE ()
)

High Fee Burden Share =
DIVIDE ( [High Fee Burden Transactions], [Transactions] )

Fees Per Customer USD =
DIVIDE ( [Total Fees USD], [Distinct Customers] )

Amount Per Customer USD =
DIVIDE ( [Total Amount USD], [Distinct Customers] )

Average Customer Score =
AVERAGE ( FactBankingTransactions[CustomerScore] )

Average Monthly Income =
AVERAGE ( FactBankingTransactions[MonthlyIncome] )

Total Amount USD Prior Month =
CALCULATE (
    [Total Amount USD],
    DATEADD ( DimDate[Date], -1, MONTH )
)

Amount USD MoM Change =
[Total Amount USD] - [Total Amount USD Prior Month]

Amount USD MoM Change % =
DIVIDE ( [Amount USD MoM Change], [Total Amount USD Prior Month] )

Total Fees USD Prior Month =
CALCULATE (
    [Total Fees USD],
    DATEADD ( DimDate[Date], -1, MONTH )
)

Fees USD MoM Change % =
DIVIDE (
    [Total Fees USD] - [Total Fees USD Prior Month],
    [Total Fees USD Prior Month]
)

City Amount Rank =
RANKX (
    ALLSELECTED ( DimBranch[BranchCity] ),
    [Total Amount USD],
    ,
    DESC,
    DENSE
)

Segment Fee Rank =
RANKX (
    ALLSELECTED ( DimCustomerProfile[CustomerSegment] ),
    [Total Fees USD],
    ,
    DESC,
    DENSE
)

Offer Amount Rank =
RANKX (
    ALLSELECTED ( DimRecommendedOffer[RecommendedOffer] ),
    [Total Amount USD],
    ,
    DESC,
    DENSE
)

Product Amount Rank =
RANKX (
    ALLSELECTED ( DimProduct[ProductCategory] ),
    [Total Amount USD],
    ,
    DESC,
    DENSE
)

Credit Card Fee Share =
DIVIDE ( [Credit Card Fees USD], [Total Fees USD] )

Insurance Fee Share =
DIVIDE ( [Insurance Fees USD], [Total Fees USD] )

Late Payment Fee Share =
DIVIDE ( [Late Payment USD], [Total Fees USD] )

Average Fees Per Transaction USD =
DIVIDE ( [Total Fees USD], [Transactions] )

Average Amount Per Transaction USD =
DIVIDE ( [Total Amount USD], [Transactions] )

Current Page Subtitle =
"USD reporting; EUR converted with daily historical EUR/USD rates"
```

Format:

- Currency: `$#,0.00`
- Counts: `#,0`
- Percentages: `0.00%`

## Sort Columns To Set

- Sort `DimDate[MonthName]` by `DimDate[MonthNumber]`.
- Sort `DimDate[YearMonth]` by `DimDate[MonthStart]`.
- Sort `DimCustomerProfile[CreditScoreBand]` by `DimCustomerProfile[CreditScoreBandOrder]`.
- Sort `DimCustomerProfile[MonthlyIncomeBand]` by `DimCustomerProfile[MonthlyIncomeBandOrder]`.
- Sort `DimTransactionValueBand[TransactionValueBandUSD]` by `DimTransactionValueBand[TransactionValueBandOrder]`.

## Page 1: Executive Overview

### Goal

Give an executive the full state of transaction activity, customer reach, value, fee revenue, and friction in one page.

### Layout

- Top row: title and subtitle.
- Second row: six KPI cards.
- Center: monthly trend.
- Right: key revenue/friction breakdown.
- Bottom: segment and city ranking.

### Visuals

1. Card: `Transactions`
   - Title: `Transactions`
   - Expected total: 20,000
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

2. Card: `Distinct Customers`
   - Title: `Customers`
   - Expected total: 8,025
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

3. Card: `Total Amount USD`
   - Title: `Transaction Value`
   - Format: currency, display units millions
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

4. Card: `Total Fees USD`
   - Title: `Fee Revenue`
   - Format: currency
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

5. Card: `Fee Rate`
   - Title: `Fee Rate`
   - Format: percentage
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

6. Card: `Late Payment USD`
   - Title: `Late Payment Exposure`
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

7. Line and clustered column chart
   - X-axis: `DimDate[YearMonth]`
   - Column values: `[Total Amount USD]`
   - Line values: `[Total Fees USD]`
   - Sort `DimDate[YearMonth]` by `DimDate[MonthStart]`
   - Column color: `#1F6F54`
   - Line color: `#0E3B2E`
   - Axis and legend text: `#1F6F54`
   - Gridlines: `#D7E7DD`
   - Title: `Monthly Value And Fee Revenue`

8. Donut chart
   - Legend: fee type labels from a small manual table, or use three separate card visuals if you want to move faster.
   - Values: `Credit Card Fees USD`, `Insurance Fees USD`, `Late Payment USD`
   - Slice color: `Credit Card Fees USD` = `#1F6F54`
   - Slice color: `Insurance Fees USD` = `#5FB88A`
   - Slice color: `Late Payment USD` = `#0E3B2E`
   - Detail labels: `#1F6F54`
   - Title: `Fee Revenue Mix`

9. Bar chart
   - Y-axis: `DimCustomerProfile[CustomerSegment]`
   - X-axis: `[Total Amount USD]`
   - Tooltip: `[Transactions]`, `[Distinct Customers]`, `[Total Fees USD]`, `[Fee Rate]`
   - Sort descending by `[Total Amount USD]`
   - Bar color: `#1F6F54`
   - Axis and label color: `#1F6F54`
   - Gridlines: `#D7E7DD`
   - Title: `Value By Customer Segment`

10. Bar chart
   - Y-axis: `DimBranch[BranchCity]`
   - X-axis: `[Total Amount USD]`
   - Tooltip: `[Transactions]`, `[Total Fees USD]`, `[City Amount Rank]`
   - Top N filter: top 8 by `[Total Amount USD]`
   - Bar color: `#5FB88A`
   - Axis and label color: `#1F6F54`
   - Gridlines: `#D7E7DD`
   - Title: `Top City Hotspots`

### QA

- Cards must match validation report.
- Trend line should span 2023-01 to 2025-05.
- All monetary labels must say USD or use `$`.

## Page 2: Customer Segments

### Goal

Explain which segments are most active, most valuable, and most exposed to fees.

### Visuals

1. Matrix
   - Rows: `DimCustomerProfile[CustomerSegment]`
   - Columns: `DimProduct[ProductCategory]`
   - Values: `[Transactions]`, `[Total Amount USD]`, `[Total Fees USD]`
   - Conditional formatting: background color on `[Total Fees USD]` from `#D7E7DD` low to `#5FB88A` high
   - Title: `Segment And Product Matrix`

2. Clustered bar chart
   - Y-axis: `DimCustomerProfile[CustomerSegment]`
   - X-axis: `[Transactions]`
   - Tooltip: `[Distinct Customers]`, `[Amount Per Customer USD]`, `[Fees Per Customer USD]`
   - Bar color: `#5FB88A`
   - Title: `Segment Activity`

3. Clustered bar chart
   - Y-axis: `DimCustomerProfile[CustomerSegment]`
   - X-axis: `[Fees Per Customer USD]`
   - Sort descending
   - Bar color: `#0E3B2E`
   - Title: `Fees Per Customer`

4. Stacked column chart
   - X-axis: `DimCustomerProfile[CreditScoreBand]`
   - Y-axis: `[Transactions]`
   - Legend: `DimCustomerProfile[CustomerSegment]`
   - Sort `DimCustomerProfile[CreditScoreBand]` by `DimCustomerProfile[CreditScoreBandOrder]`
   - Series colors: Low Income = `#D7E7DD`, Middle Income = `#5FB88A`, High Income = `#1F6F54`
   - Title: `Credit Score Distribution By Segment`

5. Scatter chart
   - X-axis: `[Average Monthly Income]`
   - Y-axis: `[Average Customer Score]`
   - Size: `[Total Fees USD]`
   - Legend: `DimCustomerProfile[CustomerSegment]`
   - Details: `DimCustomerProfile[CustomerProfileLabel]`
   - Bubble colors: Low Income = `#D7E7DD`, Middle Income = `#5FB88A`, High Income = `#1F6F54`
   - Title: `Income, Score, And Fee Exposure`

6. Table
   - Fields: `DimCustomerProfile[CustomerSegment]`, `[Transactions]`, `[Distinct Customers]`, `[Total Amount USD]`, `[Total Fees USD]`, `[High Fee Burden Share]`
   - Header background: `#0E3B2E`
   - Header text: `#F6FBF7`
   - Values text: `#1F6F54`
   - Conditional formatting: `High Fee Burden Share` from `#D7E7DD` low to `#0E3B2E` high
   - Title: `Segment Summary`

### QA

- Middle Income Segment should be the largest by transaction count.
- High fee burden should be interpreted as analytical friction, not credit decisioning.

## Page 3: Transaction Behavior

### Goal

Compare transaction type volume, value, products, and channel behavior.

### Visuals

1. Combo chart
   - X-axis: `DimTransactionType[TransactionType]`
   - Column values: `[Transactions]`
   - Line values: `[Total Amount USD]`
   - Sort by `[Transactions]`
   - Column color: `#5FB88A`
   - Line color: `#0E3B2E`
   - Title: `Transaction Type: Volume Versus Value`

2. Bar chart
   - Y-axis: `DimTransactionType[TransactionType]`
   - X-axis: `[Total Fees USD]`
   - Sort descending
   - Bar color: `#0E3B2E`
   - Title: `Fee Revenue By Transaction Type`

3. Treemap
   - Group: `DimProduct[ProductCategory]`
   - Details: `DimProduct[ProductSubcategory]`
   - Values: `[Total Amount USD]`
   - Data colors: `#1F6F54`, `#5FB88A`, `#0E3B2E`, `#D7E7DD`
   - Title: `Product Value Mix`

4. Matrix heatmap
   - Rows: `DimChannel[Channel]`
   - Columns: `DimTransactionType[TransactionType]`
   - Values: `[Transactions]`
   - Conditional formatting: background color from `#D7E7DD` low to `#0E3B2E` high
   - Title: `Channel Usage By Transaction Type`

5. Clustered bar chart
   - Y-axis: `DimChannel[Channel]`
   - X-axis: `[Total Amount USD]`
   - Legend: `DimCustomerProfile[CustomerSegment]`
   - Series colors: Low Income = `#D7E7DD`, Middle Income = `#5FB88A`, High Income = `#1F6F54`
   - Title: `Channel Value By Segment`

6. Drillthrough table
   - Fields: `FactBankingTransactions[TransactionID]`, `FactBankingTransactions[CustomerID]`, `DimDate[Date]`, `DimTransactionType[TransactionType]`, `DimProduct[ProductCategory]`, `DimChannel[Channel]`, `DimCurrency[Currency]`, `FactBankingTransactions[AmountOriginal]`, `DimCurrencyRate[RateToUSD]`, `DimCurrencyRate[FXRateDate]`, `FactBankingTransactions[AmountUSD]`
   - Header background: `#0E3B2E`
   - Header text: `#F6FBF7`
   - Values text: `#1F6F54`
   - Alternating rows: `#FFFFFF` and `#F6FBF7`
   - Title: `Transaction Audit`

### QA

- Loan Payment should stand out strongly in fee revenue.
- Original currency and `FXRateDate` should be available in audit view.

## Page 4: Revenue And Friction

### Goal

Show how fee revenue is generated and where customer friction is concentrated.

### Visuals

1. Card: `Total Fees USD`
   - Title: `Total Fees`
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

2. Card: `Credit Card Fees USD`
   - Title: `Card Fees`
   - Value color: `#1F6F54`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

3. Card: `Insurance Fees USD`
   - Title: `Insurance Fees`
   - Value color: `#5FB88A`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

4. Card: `Late Payment USD`
   - Title: `Late Payments`
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

5. Card: `Fee Transaction Share`
   - Title: `Fee Transaction Share`
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

6. Card: `High Fee Burden Share`
   - Title: `High Fee Burden Share`
   - Value color: `#0E3B2E`
   - Label color: `#1F6F54`
   - Border color: `#D7E7DD`

7. Bar chart
   - Y-axis: `DimCustomerProfile[CustomerSegment]`
   - X-axis: `[Total Fees USD]`
   - Tooltip: `[Fees Per Customer USD]`, `[Fee Rate]`, `[High Fee Burden Share]`
   - Bar color: `#0E3B2E`
   - Title: `Fee Revenue By Segment`

8. Bar chart
   - Y-axis: `DimTransactionType[TransactionType]`
   - X-axis: `[Late Payment USD]`
   - Sort descending
   - Bar color: `#0E3B2E`
   - Title: `Late Payment Exposure By Transaction Type`

9. Scatter chart
   - X-axis: `[Average Amount Per Transaction USD]`
   - Y-axis: `[Average Fees Per Transaction USD]`
   - Size: `[Transactions]`
   - Legend: `DimTransactionType[TransactionType]`
   - Data colors: use `#1F6F54`, `#5FB88A`, `#0E3B2E`, `#D7E7DD`
   - Title: `Value And Fee Friction`

10. Table
   - Filter: `FactBankingTransactions[HighFeeBurdenFlag]` is true
   - Fields: `FactBankingTransactions[CustomerID]`, `DimCustomerProfile[CustomerSegment]`, `DimTransactionType[TransactionType]`, `FactBankingTransactions[AmountUSD]`, `FactBankingTransactions[TotalFeesUSD]`, `FactBankingTransactions[FeeRate]`, `FactBankingTransactions[FeeBurdenZScore]`, `DimRecommendedOffer[RecommendedOffer]`
   - Header background: `#0E3B2E`
   - Header text: `#F6FBF7`
   - Values text: `#1F6F54`
   - Conditional formatting: `FeeRate` and `FeeBurdenZScore` from `#D7E7DD` low to `#0E3B2E` high
   - Title: `High-Fee Burden Candidates`

### QA

- High-fee table should be framed as candidate review.
- Avoid language like default, fraud, or credit risk unless backed by separate risk labels.

## Page 5: Branch And Geography

### Goal

Identify branch-city hotspots and underperforming locations.

### Visuals

1. Map
   - Latitude: `DimBranch[BranchLat]`
   - Longitude: `DimBranch[BranchLong]`
   - Size: `[Total Amount USD]`
   - Legend: `DimBranch[BranchCity]`
   - Tooltip: `[Transactions]`, `[Distinct Customers]`, `[Total Fees USD]`, `[Fee Rate]`
   - Bubble color: `#1F6F54`
   - Title: `Branch City Hotspots`

2. Bar chart
   - Y-axis: `DimBranch[BranchCity]`
   - X-axis: `[Total Amount USD]`
   - Sort descending
   - Bar color: `#1F6F54`
   - Title: `City Ranking By Value`

3. Bar chart
   - Y-axis: `DimBranch[BranchCity]`
   - X-axis: `[Transactions]`
   - Sort descending
   - Bar color: `#5FB88A`
   - Title: `City Ranking By Activity`

4. Bar chart
   - Y-axis: `DimBranch[BranchCity]`
   - X-axis: `[Total Fees USD]`
   - Sort descending
   - Bar color: `#0E3B2E`
   - Title: `City Ranking By Fee Revenue`

5. Matrix
   - Rows: `DimBranch[BranchCity]`
   - Values: `[Transactions]`, `[Distinct Customers]`, `[Total Amount USD]`, `[Total Fees USD]`, `[Fee Rate]`, `[City Amount Rank]`
   - Conditional formatting: `[Fee Rate]` and `[City Amount Rank]` from `#D7E7DD` low to `#5FB88A` high
   - Title: `City Performance Table`

6. Decomposition tree
   - Analyze: `[Total Amount USD]`
   - Explain by: `DimBranch[BranchCity]`, `DimChannel[Channel]`, `DimCustomerProfile[CustomerSegment]`, `DimProduct[ProductCategory]`, `DimTransactionType[TransactionType]`
   - Primary color: `#1F6F54`
   - Emphasis color: `#0E3B2E`
   - Connector/outline color: `#D7E7DD`
   - Title: `Value Driver Decomposition`

### QA

- Treat geography as city-level. Do not imply exact branch routing from lat/long.

## Page 6: Trends And Offers

### Goal

Show seasonality, momentum, and whether recommended offers align with observed behavior.

### Visuals

1. Line chart
   - X-axis: `DimDate[YearMonth]`
   - Y-axis: `[Transactions]`
   - Legend: `DimChannel[Channel]`
   - Series colors: Branch = `#1F6F54`, ATM = `#5FB88A`, Mobile = `#0E3B2E`
   - Title: `Monthly Activity By Channel`

2. Line chart
   - X-axis: `DimDate[YearMonth]`
   - Y-axis: `[Total Fees USD]`
   - Legend: `DimCustomerProfile[CustomerSegment]`
   - Series colors: Low Income = `#D7E7DD`, Middle Income = `#5FB88A`, High Income = `#1F6F54`
   - Title: `Monthly Fee Revenue By Segment`

3. Column chart
   - X-axis: `DimDate[Season]`
   - Y-axis: `[Total Amount USD]`
   - Legend: `DimProduct[ProductCategory]`
   - Series colors: `#1F6F54`, `#5FB88A`, `#0E3B2E`, `#D7E7DD`
   - Title: `Seasonal Product Value`

4. Matrix
   - Rows: `DimCustomerProfile[CustomerSegment]`
   - Columns: `DimRecommendedOffer[RecommendedOffer]`
   - Values: `[Transactions]`
   - Conditional formatting: background color from `#D7E7DD` low to `#0E3B2E` high
   - Title: `Offer Distribution By Segment`

5. Bar chart
   - Y-axis: `DimRecommendedOffer[RecommendedOffer]`
   - X-axis: `[Total Amount USD]`
   - Legend: `DimCustomerProfile[CustomerSegment]`
   - Series colors: Low Income = `#D7E7DD`, Middle Income = `#5FB88A`, High Income = `#1F6F54`
   - Title: `Offer-Aligned Value`

6. Table
   - Fields: `DimRecommendedOffer[RecommendedOffer]`, `DimCustomerProfile[CustomerSegment]`, `[Transactions]`, `[Total Amount USD]`, `[Total Fees USD]`, `[Average Customer Score]`, `[Average Monthly Income]`
   - Header background: `#0E3B2E`
   - Header text: `#F6FBF7`
   - Values text: `#1F6F54`
   - Conditional formatting: `Total Amount USD` from `#D7E7DD` low to `#1F6F54` high
   - Conditional formatting: `Total Fees USD` from `#D7E7DD` low to `#0E3B2E` high
   - Title: `Offer Alignment Detail`

### QA

- Offer analysis shows alignment signals, not accepted offers.
- Use wording like recommended, proposed, targeted.

## Drillthrough Page: Transaction Detail

### Setup

Create a hidden drillthrough page named `Transaction Detail`.

Drillthrough fields:

- `FactBankingTransactions[CustomerID]`
- `DimBranch[BranchCity]`
- `DimTransactionType[TransactionType]`
- `DimRecommendedOffer[RecommendedOffer]`

Visuals:

1. Card: `CustomerID`
2. Card: `[Transactions]`
3. Card: `[Total Amount USD]`
4. Card: `[Total Fees USD]`
   - Card value color: `#0E3B2E`
   - Card label color: `#1F6F54`
   - Card border color: `#D7E7DD`
5. Table:
   - `FactBankingTransactions[TransactionID]`
   - `DimDate[Date]`
   - `DimCustomerProfile[CustomerSegment]`
   - `DimTransactionType[TransactionType]`
   - `DimProduct[ProductCategory]`
   - `DimChannel[Channel]`
   - `DimCurrency[Currency]`
   - `FactBankingTransactions[AmountOriginal]`
   - `DimCurrencyRate[RateToUSD]`
   - `DimCurrencyRate[FXRateDate]`
   - `FactBankingTransactions[AmountUSD]`
   - `FactBankingTransactions[TotalFeesUSD]`
   - Header background: `#0E3B2E`
   - Header text: `#F6FBF7`
   - Values text: `#1F6F54`
   - Alternating rows: `#FFFFFF` and `#F6FBF7`

Add a back button.

- Back button fill: `#1F6F54`
- Back button text/icon: `#F6FBF7`
- Back button hover fill: `#0E3B2E`

## Tooltip Page: FX Audit

### Setup

Create a tooltip page named `FX Audit Tooltip`.

Canvas type: Tooltip.

Fields:

- `DimCurrency[Currency]`
- `FactBankingTransactions[AmountOriginal]`
- `DimCurrencyRate[RateToUSD]`
- `DimCurrencyRate[FXRateDate]`
- `DimCurrencyRate[RateSource]`
- `FactBankingTransactions[AmountUSD]`

Apply this tooltip to visuals where converted monetary values appear.

Tooltip colors:

- Tooltip page background: `#F6FBF7`.
- Tooltip card/table background: `#FFFFFF`.
- Header text: `#0E3B2E`.
- Values text: `#1F6F54`.
- Border: `#D7E7DD`.

## Interactions

For each page:

- Slicers filter all visuals.
- KPI cards should not cross-highlight other visuals.
- Charts should cross-filter tables.
- Tables should not over-filter the whole page unless used as drill/audit surfaces.

## Final QA Script

1. Clear all filters.
2. Check executive cards:
   - `Transactions` = 20,000
   - `Distinct Customers` = 8,025
   - `Total Amount USD` = $107,954,758.28
   - `Total Fees USD` = $681,084.03
3. Filter `DimCurrency[Currency] = EUR`.
4. Confirm tooltip or audit table shows:
   - `RateToUSD`
   - `FXRateDate`
   - `RateSource`
5. Filter `FactBankingTransactions[HighFeeBurdenFlag] = True`.
6. Confirm high-fee burden candidate count is 1,371.
7. Navigate through every page and confirm slicers still work.
8. Save as `banking-transaction-analytics-star-schema-v1.pbix`.

## Export Checklist

After the `.pbix` is built:

- Save `.pbix` in `docs/assets/exports/`.
- Export PDF to `docs/assets/exports/`.
- Save key page screenshots to `docs/assets/screenshots/`.
- Update `docs/publish.md` if the `.pbix` name changes.

## Unresolved Questions

- Should the report use a custom JSON theme file, or Power BI's built-in theme controls?
- Should Power BI Service publishing remain out of scope after the `.pbix` is complete?
