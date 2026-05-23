# Data Dictionary

## Source Tables

### `raw.sales`

| Column | Meaning |
| --- | --- |
| `SalesID` | Sales line identifier |
| `SalesPersonID` | Employee responsible for the sale |
| `CustomerID` | Customer identifier |
| `ProductID` | Product identifier |
| `Quantity` | Units sold |
| `Discount` | Discount rate applied to the line |
| `TotalPrice` | Source total price, zero in this dataset |
| `SalesDate` | Sales timestamp |
| `TransactionNumber` | Invoice/order identifier |

### `raw.products`

| Column | Meaning |
| --- | --- |
| `ProductID` | Product identifier |
| `ProductName` | Product label |
| `Price` | Unit list price |
| `CategoryID` | Product category identifier |
| `Class` | Product class: High, Medium, Low |
| `ModifyDate` | Product record modify date |
| `Resistant` | Product resistance attribute |
| `IsAllergic` | Allergen attribute |
| `VitalityDays` | Product vitality or shelf-life days |

### Supporting Dimensions

| Table | Purpose |
| --- | --- |
| `raw.categories` | Product category lookup |
| `raw.customers` | Customer identity and city key |
| `raw.employees` | Sales employee attributes |
| `raw.cities` | City and country key |
| `raw.countries` | Country lookup |

## Mart Views

| View | Purpose |
| --- | --- |
| `mart.vw_sales_enriched` | Joined line-level analytical base |
| `mart.vw_executive_kpis` | Portfolio KPI summary |
| `mart.vw_monthly_category_revenue` | Month and category trend analysis |
| `mart.vw_product_performance` | Product ranking and velocity |
| `mart.vw_customer_segments` | Customer value, AOV, basket size |
| `mart.vw_employee_performance` | Workforce performance over time |
| `mart.vw_geo_market` | City and country market analysis |
| `mart.vw_class_performance` | Product class consumption analysis |

## Calculated Fields

| Field | Formula |
| --- | --- |
| `GrossRevenueEstimate` | `Quantity * ProductPrice` |
| `NetRevenue` | `Quantity * ProductPrice * (1 - DiscountRate)` when `TotalPrice = 0` |
| `RevenuePerUnit` | `NetRevenue / UnitsSold` |
| `AverageOrderValue` | `NetRevenue / InvoiceCount` |
| `AverageBasketSize` | `UnitsSold / InvoiceCount` |
| `CategoryShare` | category net revenue divided by monthly net revenue |
| `MoMRevenueChange` | current month category revenue minus prior month revenue |

