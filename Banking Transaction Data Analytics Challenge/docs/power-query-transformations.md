# Power Query Transformations

## Recommended Import

For the fastest Power BI refresh, import the prepared CSV outputs:

- `docs/assets/exports/banking-transactions-prepared-usd.csv`
- `docs/assets/exports/dim-calendar.csv`
- `docs/assets/exports/currency-rates-to-usd.csv`

For the upgraded portfolio model, import the star-schema outputs instead:

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

## Fact Table Query

```powerquery
let
    Source = Csv.Document(
            File.Contents("<cloned-repo-path>\\docs\\assets\\exports\\banking-transactions-prepared-usd.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            {"TransactionID", Int64.Type},
            {"CustomerID", Int64.Type},
            {"TransactionDate", type date},
            {"Year", Int64.Type},
            {"Quarter", type text},
            {"MonthNumber", Int64.Type},
            {"MonthName", type text},
            {"YearMonth", type text},
            {"MonthStart", type date},
            {"Season", type text},
            {"TransactionType", type text},
            {"ProductCategory", type text},
            {"ProductSubcategory", type text},
            {"BranchCity", type text},
            {"BranchLat", type number},
            {"BranchLong", type number},
            {"Channel", type text},
            {"Currency", type text},
            {"RateToUSD", type number},
            {"FXRateDate", type date},
            {"RateSource", type text},
            {"AmountOriginal", Currency.Type},
            {"AmountUSD", Currency.Type},
            {"CreditCardFeesOriginal", Currency.Type},
            {"CreditCardFeesUSD", Currency.Type},
            {"InsuranceFeesOriginal", Currency.Type},
            {"InsuranceFeesUSD", Currency.Type},
            {"LatePaymentAmountOriginal", Currency.Type},
            {"LatePaymentAmountUSD", Currency.Type},
            {"TotalFeesOriginal", Currency.Type},
            {"TotalFeesUSD", Currency.Type},
            {"FeeRate", Percentage.Type},
            {"HasFeeFriction", type logical},
            {"HasLatePayment", type logical},
            {"CustomerScore", Int64.Type},
            {"CreditScoreBand", type text},
            {"MonthlyIncome", Currency.Type},
            {"MonthlyIncomeBand", type text},
            {"CustomerSegment", type text},
            {"TransactionValueBandUSD", type text},
            {"RecommendedOffer", type text},
            {"FeeBurdenZScore", type number},
            {"HighFeeBurdenFlag", type logical}
        }
    )
in
    ChangedTypes
```

## Calendar Query

```powerquery
let
    Source = Csv.Document(
        File.Contents("<cloned-repo-path>\\docs\\assets\\exports\\dim-calendar.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            {"Date", type date},
            {"Year", Int64.Type},
            {"Quarter", type text},
            {"MonthNumber", Int64.Type},
            {"MonthName", type text},
            {"YearMonth", type text},
            {"MonthStart", type date},
            {"Season", type text}
        }
    )
in
    ChangedTypes
```

## Currency Rates Query

```powerquery
let
    Source = Csv.Document(
        File.Contents("<cloned-repo-path>\\docs\\assets\\exports\\currency-rates-to-usd.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            {"Date", type date},
            {"Currency", type text},
            {"RateToUSD", type number},
            {"FXRateDate", type date},
            {"RateSource", type text}
        }
    )
in
    ChangedTypes
```

## Relationship Setup

- Relate `DimCalendar[Date]` to `FactBankingTransactions[TransactionDate]`.
- Keep `CurrencyRates` disconnected unless you rebuild or audit FX conversion inside Power Query.
- Mark `DimCalendar` as the date table.

## Star Schema Relationship Setup

Use this setup after importing `fact-banking-transactions-star.csv`.

- Relate `DimDate[DateKey]` to `FactBankingTransactions[DateKey]`.
- Relate `DimCustomer[CustomerID]` to `FactBankingTransactions[CustomerID]`.
- Relate `DimCustomerProfile[CustomerProfileKey]` to `FactBankingTransactions[CustomerProfileKey]`.
- Relate `DimProduct[ProductKey]` to `FactBankingTransactions[ProductKey]`.
- Relate `DimBranch[BranchKey]` to `FactBankingTransactions[BranchKey]`.
- Relate `DimChannel[ChannelKey]` to `FactBankingTransactions[ChannelKey]`.
- Relate `DimTransactionType[TransactionTypeKey]` to `FactBankingTransactions[TransactionTypeKey]`.
- Relate `DimRecommendedOffer[OfferKey]` to `FactBankingTransactions[OfferKey]`.
- Relate `DimCurrency[CurrencyKey]` to `FactBankingTransactions[CurrencyKey]`.
- Relate `DimCurrencyRate[CurrencyRateKey]` to `FactBankingTransactions[CurrencyRateKey]`.
- Relate `DimTransactionValueBand[TransactionValueBandKey]` to `FactBankingTransactions[TransactionValueBandKey]`.
- Keep all relationships one-to-many with single filter direction from dimension to fact.
- Mark `DimDate[Date]` as the date table.
- Hide fact foreign keys after relationships are created.

For local refresh, point Power BI to the cloned repo's `docs/assets/exports` folder and verify the model relationships listed in `README.md`.

## Refresh Note

The `.pbix` is the first delivery target. The prepared CSV path is stable for local Power BI Desktop work. If this project later moves to Power BI Service, place files in OneDrive, SharePoint, or a gateway-accessible folder and update `File.Contents` paths.
