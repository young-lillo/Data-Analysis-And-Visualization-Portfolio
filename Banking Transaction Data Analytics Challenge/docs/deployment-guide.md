# Deployment Guide

This project is packaged for GitHub portfolio deployment, public Power BI viewing, and local Power BI Desktop review.

## Public Dashboard

[View the published Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNjgyMTFlMGUtZGI1YS00NGMyLTk0ZmEtODUxODRlMzE2NWYzIiwidCI6IjM3MGZiM2I4LTMzMDYtNDg5MC05MDYzLWNjMDhiZTc4ODI1NyIsImMiOjEwfQ%3D%3D)

## Repository Target

Recommended repository name:

```text
banking-transaction-data-analytics-challenge
```

Recommended description:

```text
Power BI banking transaction analytics project with USD normalization, star schema modeling, fee revenue analysis, customer segmentation, branch performance, offer alignment, and a published dashboard.
```

## Local Setup

```bash
git clone https://github.com/<your-username>/banking-transaction-data-analytics-challenge.git
cd banking-transaction-data-analytics-challenge
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python tools/build-banking-star-schema.py
```

## Power BI Setup

1. Open `powerbi/banking-transaction-analytics-star-schema.pbix`.
2. If Power BI cannot find the CSV files, open `Transform data`.
3. Update the file paths to the cloned repo path under `docs/assets/exports`.
4. Refresh.
5. Check the KPI cards:
   - Transactions: `20,000`
   - Distinct Customers: `8,025`
   - Total Amount USD: `$107,954,758.28`
   - Total Fees USD: `$681,084.03`
   - High-Fee Burden Candidates: `1,371`

## Data Model

Use one-to-many relationships from dimensions to fact:

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

Keep filter direction single from dimension to fact.

## GitHub Checklist

- README has project context, methodology, published Power BI URL, screenshots, and key outputs.
- Power BI files are under `powerbi/`.
- Prepared data and star-schema tables are under `docs/assets/exports/`.
- Dashboard screenshots are under `docs/assets/screenshots/`.
- PDF export is under `docs/assets/reports/`.
- `.env`, `.venv`, cache folders, and build artifacts are ignored.
- No credentials, private API keys, gateway secrets, refresh tokens, or private workspace settings are included.

## Publish Notes

Power BI `.pbix` files are binary files. GitHub can store this project size, but for larger future projects consider Git LFS for `.pbix` and raw data files.

If publishing from the portfolio monorepo, commit this folder as a new project. If publishing as a standalone repo, use this project folder as the repo root.

Power BI Service refresh configuration should stay outside the repository because credentials, gateway details, and workspace settings are environment-specific.
