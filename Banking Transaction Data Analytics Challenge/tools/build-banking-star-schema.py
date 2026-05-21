"""Reproducible checks and star-schema exports for the banking Power BI dataset."""

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
HERE = PROJECT_ROOT / "docs" / "assets" / "exports"
FACT_PATH = HERE / "banking-transactions-prepared-usd.csv"
FX_PATH = HERE / "currency-rates-to-usd.csv"
CALENDAR_PATH = HERE / "dim-calendar.csv"

STAR_FACT_PATH = HERE / "fact-banking-transactions-star.csv"
STAR_VALIDATION_PATH = HERE / "star-schema-validation.json"

SCORE_ORDER = {
    "Poor": 1,
    "Fair": 2,
    "Good": 3,
    "Very Good": 4,
    "Exceptional": 5,
}

INCOME_ORDER = {
    "Under 3k": 1,
    "3k-6k": 2,
    "6k-10k": 3,
}

VALUE_BAND_ORDER = {
    "Under 1k": 1,
    "1k-5k": 2,
    "5k-10k": 3,
    "10k+": 4,
}


def load_data():
    fact = pd.read_csv(
        FACT_PATH,
        parse_dates=["TransactionDate", "MonthStart", "FXRateDate"],
    )
    fx = pd.read_csv(FX_PATH, parse_dates=["Date", "FXRateDate"])
    return fact, fx


def summarize():
    fact, fx = load_data()
    eur_rates = fx.loc[fx["Currency"] == "EUR", "RateToUSD"]
    return {
        "rows": int(len(fact)),
        "distinct_customers": int(fact["CustomerID"].nunique()),
        "date_min": str(fact["TransactionDate"].min().date()),
        "date_max": str(fact["TransactionDate"].max().date()),
        "currencies": sorted(fact["Currency"].unique().tolist()),
        "fx_method": "Daily historical EUR/USD; previous published rate used for non-publication dates; native USD = 1.0",
        "eur_rate_min": round(float(eur_rates.min()), 6),
        "eur_rate_max": round(float(eur_rates.max()), 6),
        "total_amount_usd": round(float(fact["AmountUSD"].sum()), 2),
        "total_fees_usd": round(float(fact["TotalFeesUSD"].sum()), 2),
        "high_fee_burden_candidates": int(fact["HighFeeBurdenFlag"].sum()),
    }


def _with_sequential_key(frame, key_name, prefix):
    result = frame.reset_index(drop=True).copy()
    result.insert(0, key_name, [f"{prefix}{i:03d}" for i in range(1, len(result) + 1)])
    return result


def _mode(series):
    modes = series.dropna().mode()
    return modes.iloc[0] if not modes.empty else None


def build_star_schema():
    fact, fx = load_data()

    fact = fact.copy()
    fact["DateKey"] = fact["TransactionDate"].dt.strftime("%Y%m%d").astype(int)
    fact["CurrencyRateKey"] = (
        fact["FXRateDate"].dt.strftime("%Y%m%d") + "-" + fact["Currency"].astype(str)
    )

    dim_date = pd.read_csv(CALENDAR_PATH, parse_dates=["Date", "MonthStart"])
    dim_date.insert(0, "DateKey", dim_date["Date"].dt.strftime("%Y%m%d").astype(int))

    dim_product = _with_sequential_key(
        fact[["ProductCategory", "ProductSubcategory"]]
        .drop_duplicates()
        .sort_values(["ProductCategory", "ProductSubcategory"]),
        "ProductKey",
        "P",
    )

    dim_branch = _with_sequential_key(
        fact[["BranchCity", "BranchLat", "BranchLong"]]
        .drop_duplicates()
        .sort_values(["BranchCity"]),
        "BranchKey",
        "B",
    )

    dim_channel = _with_sequential_key(
        fact[["Channel"]].drop_duplicates().sort_values(["Channel"]),
        "ChannelKey",
        "CH",
    )

    dim_transaction_type = _with_sequential_key(
        fact[["TransactionType"]].drop_duplicates().sort_values(["TransactionType"]),
        "TransactionTypeKey",
        "TT",
    )

    dim_offer = _with_sequential_key(
        fact[["RecommendedOffer"]].drop_duplicates().sort_values(["RecommendedOffer"]),
        "OfferKey",
        "O",
    )

    dim_currency = _with_sequential_key(
        fact[["Currency"]].drop_duplicates().sort_values(["Currency"]),
        "CurrencyKey",
        "CUR",
    )

    profile_cols = ["CustomerSegment", "CreditScoreBand", "MonthlyIncomeBand"]
    dim_customer_profile = (
        fact[profile_cols]
        .drop_duplicates()
        .assign(
            CreditScoreBandOrder=lambda d: d["CreditScoreBand"].map(SCORE_ORDER),
            MonthlyIncomeBandOrder=lambda d: d["MonthlyIncomeBand"].map(INCOME_ORDER),
        )
        .sort_values(
            [
                "CustomerSegment",
                "CreditScoreBandOrder",
                "MonthlyIncomeBandOrder",
            ]
        )
    )
    dim_customer_profile = _with_sequential_key(
        dim_customer_profile,
        "CustomerProfileKey",
        "CP",
    )
    dim_customer_profile["CustomerProfileLabel"] = (
        dim_customer_profile["CustomerSegment"]
        + " | "
        + dim_customer_profile["CreditScoreBand"]
        + " | "
        + dim_customer_profile["MonthlyIncomeBand"]
    )

    dim_transaction_value_band = _with_sequential_key(
        fact[["TransactionValueBandUSD"]]
        .drop_duplicates()
        .assign(
            TransactionValueBandOrder=lambda d: d["TransactionValueBandUSD"].map(
                VALUE_BAND_ORDER
            )
        )
        .sort_values(["TransactionValueBandOrder"]),
        "TransactionValueBandKey",
        "TV",
    )

    customer_profile_stats = fact.groupby("CustomerID").agg(
        Transactions=("TransactionID", "count"),
        FirstTransactionDate=("TransactionDate", "min"),
        LastTransactionDate=("TransactionDate", "max"),
        PrimaryCustomerSegment=("CustomerSegment", _mode),
        PrimaryCreditScoreBand=("CreditScoreBand", _mode),
        PrimaryMonthlyIncomeBand=("MonthlyIncomeBand", _mode),
        AverageCustomerScore=("CustomerScore", "mean"),
        AverageMonthlyIncome=("MonthlyIncome", "mean"),
        TotalAmountUSD=("AmountUSD", "sum"),
        TotalFeesUSD=("TotalFeesUSD", "sum"),
        HighFeeBurdenTransactions=("HighFeeBurdenFlag", "sum"),
        SegmentVersionCount=("CustomerSegment", "nunique"),
        ScoreVersionCount=("CustomerScore", "nunique"),
        IncomeVersionCount=("MonthlyIncome", "nunique"),
    )
    dim_customer = customer_profile_stats.reset_index()
    dim_customer["ProfileChangesDetected"] = (
        (dim_customer["SegmentVersionCount"] > 1)
        | (dim_customer["ScoreVersionCount"] > 1)
        | (dim_customer["IncomeVersionCount"] > 1)
    )

    dim_currency_rate = fx.copy()
    dim_currency_rate.insert(
        0,
        "CurrencyRateKey",
        dim_currency_rate["FXRateDate"].dt.strftime("%Y%m%d")
        + "-"
        + dim_currency_rate["Currency"].astype(str),
    )
    dim_currency_rate = dim_currency_rate.drop_duplicates("CurrencyRateKey")

    key_maps = {
        "ProductKey": (dim_product, ["ProductCategory", "ProductSubcategory"]),
        "BranchKey": (dim_branch, ["BranchCity", "BranchLat", "BranchLong"]),
        "ChannelKey": (dim_channel, ["Channel"]),
        "TransactionTypeKey": (dim_transaction_type, ["TransactionType"]),
        "OfferKey": (dim_offer, ["RecommendedOffer"]),
        "CurrencyKey": (dim_currency, ["Currency"]),
        "CustomerProfileKey": (dim_customer_profile, profile_cols),
        "TransactionValueBandKey": (
            dim_transaction_value_band,
            ["TransactionValueBandUSD"],
        ),
    }

    star_fact = fact.copy()
    for key, (dimension, join_cols) in key_maps.items():
        star_fact = star_fact.merge(dimension[[key] + join_cols], on=join_cols, how="left")

    star_fact_columns = [
        "TransactionID",
        "CustomerID",
        "DateKey",
        "ProductKey",
        "BranchKey",
        "ChannelKey",
        "TransactionTypeKey",
        "OfferKey",
        "CurrencyKey",
        "CurrencyRateKey",
        "CustomerProfileKey",
        "TransactionValueBandKey",
        "AmountOriginal",
        "AmountUSD",
        "CreditCardFeesOriginal",
        "CreditCardFeesUSD",
        "InsuranceFeesOriginal",
        "InsuranceFeesUSD",
        "LatePaymentAmountOriginal",
        "LatePaymentAmountUSD",
        "TotalFeesOriginal",
        "TotalFeesUSD",
        "FeeRate",
        "HasFeeFriction",
        "HasLatePayment",
        "CustomerScore",
        "MonthlyIncome",
        "FeeBurdenZScore",
        "HighFeeBurdenFlag",
    ]
    star_fact = star_fact[star_fact_columns]

    outputs = {
        "fact-banking-transactions-star.csv": star_fact,
        "dim-date-star.csv": dim_date,
        "dim-customer.csv": dim_customer,
        "dim-customer-profile.csv": dim_customer_profile,
        "dim-product.csv": dim_product,
        "dim-branch.csv": dim_branch,
        "dim-channel.csv": dim_channel,
        "dim-transaction-type.csv": dim_transaction_type,
        "dim-recommended-offer.csv": dim_offer,
        "dim-currency.csv": dim_currency,
        "dim-currency-rate.csv": dim_currency_rate,
        "dim-transaction-value-band.csv": dim_transaction_value_band,
    }

    for filename, frame in outputs.items():
        frame.to_csv(HERE / filename, index=False)

    validation = {
        "fact_rows": int(len(star_fact)),
        "source_rows": int(len(fact)),
        "duplicate_transaction_ids": int(star_fact["TransactionID"].duplicated().sum()),
        "missing_foreign_keys": {
            column: int(star_fact[column].isna().sum())
            for column in [
                "DateKey",
                "ProductKey",
                "BranchKey",
                "ChannelKey",
                "TransactionTypeKey",
                "OfferKey",
                "CurrencyKey",
                "CurrencyRateKey",
                "CustomerProfileKey",
                "TransactionValueBandKey",
            ]
        },
        "distinct_customers": int(star_fact["CustomerID"].nunique()),
        "dim_customer_rows": int(len(dim_customer)),
        "dim_customer_profile_rows": int(len(dim_customer_profile)),
        "customers_with_profile_changes": int(dim_customer["ProfileChangesDetected"].sum()),
        "total_amount_usd": round(float(star_fact["AmountUSD"].sum()), 2),
        "total_fees_usd": round(float(star_fact["TotalFeesUSD"].sum()), 2),
        "high_fee_burden_candidates": int(star_fact["HighFeeBurdenFlag"].sum()),
    }
    pd.Series(validation, dtype="object").to_json(STAR_VALIDATION_PATH, indent=2)
    return validation


if __name__ == "__main__":
    validation = build_star_schema()
    print("star_schema_exports: complete")
    for key, value in validation.items():
        print(f"{key}: {value}")
    print()
    for key, value in summarize().items():
        print(f"{key}: {value}")
