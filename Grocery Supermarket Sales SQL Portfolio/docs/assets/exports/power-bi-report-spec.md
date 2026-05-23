# Power BI Report Spec

## Data Sources

Import the cooked CSV marts from this folder:

- `mart-executive-kpis.csv`
- `mart-monthly-category-revenue.csv`
- `mart-product-performance.csv`
- `mart-customer-segments.csv`
- `mart-employee-performance.csv`
- `mart-geo-market.csv`
- `mart-class-performance.csv`

## Page 1: Executive Overview

- KPI cards: `NetRevenue`, `GrossRevenueEstimate`, `UnitsSold`, `InvoiceCount`, `CustomerCount`, `AverageOrderValue`, `AverageBasketSize`.
- Line chart: `SalesMonth` by `NetRevenue` from `mart-monthly-category-revenue`.
- Stacked column: `SalesMonth`, `CategoryName`, `NetRevenue`.
- Table: top city/country rows from `mart-geo-market`.

## Page 2: Product And Inventory

- Top 5 products: filter `RevenueRankDesc <= 5`.
- Bottom 5 products: filter `RevenueRankAsc <= 5`.
- Scatter: `UnitsSold` versus `NetRevenue`, details `ProductName`, legend `Class`.
- Matrix: `CategoryName`, `Class`, `NetRevenue`, `UnitsSold`, `RevenuePerUnit`.

## Page 3: Customer Behavior

- Cards: `CustomerCount`, `RepeatCustomerRatio`, `AverageOrderValue`, `AverageBasketSize`.
- Donut or bar: `CustomerType` by customer count.
- Table: `CustomerName`, `InvoiceCount`, `NetRevenue`, `AverageOrderValue`, `AverageBasketSize`.
- Note: current cooked rule classifies all selling customers as repeat customers.

## Page 4: Workforce Performance

- Bar: `EmployeeName` by `NetRevenue`.
- Line: `SalesMonth` by `NetRevenue`, legend `EmployeeName`.
- Table: `EmployeeName`, `InvoiceCount`, `UnitsSold`, `MonthlyContributionShare`.

## Page 5: Geographic Market

- Map: `CityName`, `CountryName`, `NetRevenue`.
- Bar: top cities by `NetRevenue`.
- Matrix: `CountryName`, `CityName`, `NetRevenue`, `UnitsSold`, `CustomerCount`, `InvoiceCount`.

## Page 6: Data Quality And Method

- Cards from `data-preparation-summary.json` values:
  - sales rows: 6,758,125
  - blank sales dates: 67,526
  - zero total price rows: 6,758,125
- Text note: net revenue is calculated from `Quantity * Price * (1 - Discount)`.
- Table or text box: source-to-mart lineage.

## Design Notes

- Use restrained executive dashboard styling.
- Keep slicers compact: month, category, class, city/country, employee.
- Add tooltip pages for product, employee, and geography details if building a full `.pbix`.
- Add drillthrough pages only after core pages are stable.
