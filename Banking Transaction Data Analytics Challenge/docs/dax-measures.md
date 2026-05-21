# DAX Measures

Use these measures after loading the flat CSV as `FactBankingTransactions` and `dim-calendar.csv` as `DimCalendar`.

For the upgraded star schema, load `fact-banking-transactions-star.csv` as `FactBankingTransactions` and `dim-date-star.csv` as `DimDate`. The base measures still work because the financial columns remain in the fact table.

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
    DATEADD ( DimCalendar[Date], -1, MONTH )
)

Amount USD MoM Change =
[Total Amount USD] - [Total Amount USD Prior Month]

Amount USD MoM Change % =
DIVIDE ( [Amount USD MoM Change], [Total Amount USD Prior Month] )

Total Fees USD Prior Month =
CALCULATE (
    [Total Fees USD],
    DATEADD ( DimCalendar[Date], -1, MONTH )
)

Fees USD MoM Change % =
DIVIDE (
    [Total Fees USD] - [Total Fees USD Prior Month],
    [Total Fees USD Prior Month]
)

City Amount Rank =
RANKX (
    ALLSELECTED ( FactBankingTransactions[BranchCity] ),
    [Total Amount USD],
    ,
    DESC,
    DENSE
)

Segment Fee Rank =
RANKX (
    ALLSELECTED ( FactBankingTransactions[CustomerSegment] ),
    [Total Fees USD],
    ,
    DESC,
    DENSE
)
```

## Star Schema Replacements

When using the star-schema model, replace the time-intelligence and rank measures below.

```DAX
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
```

## Star Schema Visual Field Map

- Segment visuals: use `DimCustomerProfile[CustomerSegment]`.
- Score-band visuals: use `DimCustomerProfile[CreditScoreBand]`.
- Income-band visuals: use `DimCustomerProfile[MonthlyIncomeBand]`.
- Product visuals: use `DimProduct[ProductCategory]` and `DimProduct[ProductSubcategory]`.
- City/map visuals: use `DimBranch[BranchCity]`, `DimBranch[BranchLat]`, and `DimBranch[BranchLong]`.
- Channel visuals: use `DimChannel[Channel]`.
- Transaction-type visuals: use `DimTransactionType[TransactionType]`.
- Offer visuals: use `DimRecommendedOffer[RecommendedOffer]`.
- Currency slicer: use `DimCurrency[Currency]`.

## Formatting

- Currency measures: `$#,0.00`
- Count measures: `#,0`
- Rate/share measures: `0.00%`

## Notes

- All primary financial measures use USD fields.
- Keep original monetary fields for audit table visuals only.
- High-fee burden logic is an analytical flag, not a credit-risk decision.
