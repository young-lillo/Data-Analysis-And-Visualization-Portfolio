# Analysis Summary

## Profile

- Rows: 20,000
- Distinct customers: 8,025
- Date range: 2023-01-01 to 2025-05-20
- Source currencies: EUR, USD
- Reporting currency: USD
- FX method: Daily historical EUR/USD from Frankfurter API v2 with provider=ECB; previous available published rate used for weekends/holidays; native USD=1.00.
- EUR/USD rate range used: 1.0198 to 1.1476
- Total amount USD: $107,954,758.28
- Total fee revenue USD: $681,084.03

## Top Segments By Activity

| CustomerSegment | Transactions | Customers | TotalAmountUSD | TotalFeesUSD |
| --- | --- | --- | --- | --- |
| Middle Income Segment | 8,885 | 5,680 | 48,653,984.65 | 306,406.03 |
| High Income Segment | 6,626 | 4,647 | 35,643,297.64 | 224,733.03 |
| Low Income Segment | 4,489 | 3,530 | 23,657,475.99 | 149,944.97 |

## Transaction Types By Count

| TransactionType | Transactions | TotalAmountUSD | TotalFeesUSD |
| --- | --- | --- | --- |
| Withdrawal | 3,395 | 18,230,044.14 | 58,928.11 |
| Loan Payment | 3,369 | 18,085,810.14 | 409,935.30 |
| Card Payment | 3,345 | 17,812,755.67 | 52,862.43 |
| Fee | 3,308 | 17,794,066.53 | 53,825.68 |
| Transfer | 3,293 | 18,052,642.45 | 54,506.70 |

## Transaction Types By Value

| TransactionType | Transactions | TotalAmountUSD | TotalFeesUSD |
| --- | --- | --- | --- |
| Withdrawal | 3,395 | 18,230,044.14 | 58,928.11 |
| Loan Payment | 3,369 | 18,085,810.14 | 409,935.30 |
| Transfer | 3,293 | 18,052,642.45 | 54,506.70 |
| Deposit | 3,290 | 17,979,439.35 | 51,025.81 |
| Card Payment | 3,345 | 17,812,755.67 | 52,862.43 |

## City Hotspots By Value

| BranchCity | Transactions | Customers | TotalAmountUSD | TotalFeesUSD |
| --- | --- | --- | --- | --- |
| Barcelona | 2,564 | 2,230 | 13,915,054.97 | 90,929.32 |
| Malaga | 2,524 | 2,193 | 13,802,221.35 | 90,865.97 |
| Murcia | 2,564 | 2,218 | 13,792,049.96 | 91,136.98 |
| Seville | 2,513 | 2,203 | 13,557,342.53 | 79,057.06 |
| Zaragoza | 2,476 | 2,156 | 13,494,232.53 | 80,899.21 |

## Validation Notes

- No duplicate `TransactionID` values found: True.
- Monetary USD fields were created from original values using transaction-date `RateToUSD`.
- Original currency and original monetary fields are preserved in the prepared fact table.
- `FXRateDate` records the published rate date actually used.
- High-fee burden candidates use segment-level z-score on `TotalFeesUSD`; treat as analytical candidates, not risk decisions.

## Unresolved Questions

- None.
