# Grocery Supermarket Sales SQL Portfolio

SQL portfolio project analyzing a multinational grocery supermarket sales snapshot from January 1, 2018 to April 30, 2018. The project uses raw CSV files, SQL Server scripts, and business analysis queries to answer retail planning questions for category management, customer strategy, workforce performance, and marketing bundle readiness.

## Why This Dataset Is Challenging

This is not a small sample dataset. The project works with a large retail transaction file and several connected dimension tables:

| Dataset characteristic | Scale |
| --- | ---: |
| Sales transaction rows | 6,758,125 |
| `sales.csv` file size | 517 MB |
| Product categories | 11 |
| Products | 452 |
| Customers | 98,759 |
| Employees | 23 |
| Cities | 96 |
| Countries | 206 |

The main difficulty is that the analysis has to join a 500 MB+ line-level sales table to product, customer, employee, city, country, and category dimensions without losing invoice-level accuracy. Several questions also require more than basic aggregation: customer segmentation, category share by month, rolling 30-day employee revenue, unsold SKU detection, and basket-readiness checks.

The dataset also includes data-quality constraints. `sales.TotalPrice` is zero for every processed row, so revenue cannot be trusted directly from the source file. The SQL model recalculates revenue from quantity, product price, and discount rate, then uses the cleaned mart layer for business analysis.

## Project Files

```text
Grocery Supermarket Sales SQL Portfolio/
|-- README.md
|-- source-data/
|   |-- categories.csv
|   |-- cities.csv
|   |-- countries.csv
|   |-- customers.csv
|   |-- employees.csv
|   |-- products.csv
|   `-- sales.csv
`-- sql/
    |-- 00-create-database-and-schema.sql
    |-- 01-load-raw-csv-bulk-insert.sql
    |-- 02-analytics-views.sql
    |-- 03-business-analysis-queries.sql
    `-- 04-validation-queries.sql
```

Main analysis file: `sql/03-business-analysis-queries.sql`

## Suggested Problem Statements

1. How can a supermarket use four months of transaction data to improve category planning, customer targeting, cashier performance, and replenishment decisions?
2. Which product categories, products, cities, customer groups, and employees create the strongest commercial signals in a grocery sales snapshot?
3. What revenue, loyalty, product mix, and basket-combination patterns should management use for the next quarterly merchandising plan?
4. How can SQL turn raw supermarket transactions into actionable insights for inventory clearance, store-location planning, marketing bundles, and executive reporting?

Selected project statement:

> Analyze a four-month grocery supermarket sales snapshot to identify revenue seasonality, category mix, product velocity, customer value, employee performance, unsold catalog SKUs, and product bundle readiness.

## Dataset

The `source-data/` folder contains seven relational CSV files:

| File | Description |
| --- | --- |
| `categories.csv` | Product category lookup |
| `cities.csv` | City lookup |
| `countries.csv` | Country lookup |
| `customers.csv` | Customer profile and city key |
| `employees.csv` | Cashier / salesperson profile |
| `products.csv` | Product catalog, category, class, and list price |
| `sales.csv` | Line-level sales transactions |

Known data quality note: `sales.TotalPrice` is zero for every processed row. Revenue is calculated in SQL as:

```text
NetRevenue = Quantity * ProductPrice * (1 - DiscountRate)
```

## Dataset Analysis

### 1. Which product categories are in the current catalog, and how many products are in each category?

The catalog contains 11 categories and 452 products. Confections has the largest assortment with 57 products, followed by Meat with 50 and Poultry with 47. Grain has the smallest assortment with 28 products.

| Category | Product count |
| --- | ---: |
| Beverages | 38 |
| Cereals | 45 |
| Confections | 57 |
| Dairy | 35 |
| Grain | 28 |
| Meat | 50 |
| Poultry | 47 |
| Produce | 43 |
| Seafood | 36 |
| Shell fish | 36 |
| Snails | 37 |

Key insights:

- Confections is the broadest category with 57 products, which means it likely needs tighter shelf-space, pricing, and promotion governance than smaller categories.
- Meat and Poultry also carry large assortments, so operational teams should monitor stockouts and replenishment frequency closely in these categories.
- Grain has the smallest assortment with 28 products. If Grain revenue underperforms, the issue may be limited product breadth rather than only weak demand.
- The catalog is fairly diversified across 11 categories, reducing dependence on one single department.
- A useful next analysis would compare product count against revenue share to identify over-assorted categories and under-assorted growth opportunities.

### 2. Which 10 cities have the largest customer base for location planning?

The top customer-base cities are all in the United States. Tucson leads with 1,104 customers, followed closely by Columbus with 1,096 and Indianapolis with 1,090.

| Rank | City | Country | Customers |
| ---: | --- | --- | ---: |
| 1 | Tucson | United States | 1,104 |
| 2 | Columbus | United States | 1,096 |
| 3 | Indianapolis | United States | 1,090 |
| 4 | Fort Wayne | United States | 1,088 |
| 5 | Sacramento | United States | 1,085 |
| 6 | Charlotte | United States | 1,082 |
| 7 | Phoenix | United States | 1,079 |
| 8 | Yonkers | United States | 1,075 |
| 9 | Honolulu | United States | 1,070 |
| 10 | Oklahoma | United States | 1,069 |

Key insights:

- The top 10 customer-base cities are all in the United States, so the strongest expansion signal in this dataset is US-market concentration.
- Tucson leads, but the gap between rank 1 and rank 10 is only 35 customers. This means no single city dominates enough to make an automatic site decision.
- Because the top cities are tightly clustered, location planning should combine customer count with revenue per customer, store operating costs, delivery coverage, and competitor density.
- The result is more useful as a shortlist than a final recommendation. Tucson, Columbus, Indianapolis, Fort Wayne, and Sacramento should be prioritized for deeper market screening.
- If the company wants geographic diversification, the current customer file does not show a strong non-US city among the top 10.

### 3. Which month produced the highest revenue in the January-April 2018 snapshot?

March 2018 produced the highest revenue at USD 1.03B.

| Month | Revenue |
| --- | ---: |
| 2018-01 | 1,030,735,897.00 |
| 2018-02 | 929,204,217.48 |
| 2018-03 | 1,032,200,775.73 |
| 2018-04 | 997,268,501.06 |

Key insights:

- March is the highest-revenue month at USD 1.032B, but it is only slightly higher than January. The peak is real, but not dramatically above the next-best month.
- February is the lowest month at USD 929.2M, around USD 101.5M below January and USD 103.0M below March.
- The pattern suggests a February dip followed by a March rebound, which matters for quarterly buying and warehouse capacity planning.
- Inventory planning should avoid using February as the baseline for the next quarter because it would understate demand.
- A board-level view should show both monthly revenue and cumulative revenue so stakeholders see the dip without missing the overall four-month scale.

### 4. What are the best-selling products inside each category by total units sold?

The SQL file returns the top 5 products in each category. The top ranked product by category is:

| Category | Top product | Units sold |
| --- | --- | ---: |
| Beverages | Onion Powder | 182,519 |
| Cereals | Cookies Cereal Nut | 181,841 |
| Confections | Beans - Kidney White | 181,768 |
| Dairy | Beef - Short Loin | 182,364 |
| Grain | Isomalt | 181,219 |
| Meat | Clam Nectar | 182,905 |
| Poultry | Thyme - Lemon, Fresh | 182,663 |
| Produce | Beef - Chuck, Boneless | 182,613 |
| Seafood | Yoghurt Tubes | 183,315 |
| Shell fish | Appetizer - Mini Egg Roll, Shrimp | 181,706 |
| Snails | Longos - Chicken Wings | 184,268 |

Key insights:

- The top product in every category sells within a narrow band of roughly 181K-184K units, so no category has a single runaway product that overwhelms the rest.
- This balanced velocity means replenishment should be broad and disciplined, not focused only on one hero SKU.
- The product names look synthetic and sometimes do not match their category intuitively, so the business should trust the product/category keys rather than product labels alone.
- Category managers should review the full top 5 list in SQL, not only the number 1 product, because the rank gap may be small inside each category.
- A useful next step is to compare units sold against revenue per unit to find products that sell heavily but contribute weak margin or revenue.

### 5. What is the average order value at invoice level?

The invoice-level average order value is USD 641.00.

Key insights:

- The average order value is USD 641.00 when revenue is grouped by `TransactionNumber`.
- The query intentionally calculates AOV at invoice level before averaging, which prevents the common mistake of treating sales lines as orders.
- In this dataset, each `TransactionNumber` is unique per sales line, so AOV behaves like average transaction-line revenue.
- This is an important data limitation: the value is useful for SQL demonstration, but it should not be interpreted as a true multi-item basket benchmark.
- For a production dataset, the next requirement would be a stable basket or receipt ID that can contain multiple product lines.

### 6. What share of customers are repeat buyers versus one-time buyers?

All 98,759 customers in the snapshot are repeat buyers. No one-time customer appears in the four-month period.

| Customer group | Customers | Share |
| --- | ---: | ---: |
| Repeat | 98,759 | 100.00% |
| One-time | 0 | 0.00% |

Key insights:

- All 98,759 customers appear as repeat buyers in the four-month snapshot, while the one-time group has 0 customers.
- This is an unusually high repeat rate and strongly suggests synthetic or pre-filtered customer behavior.
- The SQL still returns both groups, including the zero-count one-time group, so the output matches stakeholder reporting requirements.
- From a business perspective, the result should not be used as a real retention benchmark without validating the customer and invoice generation process.
- If this were a real business dataset, marketing would shift from acquisition diagnostics to frequency, loyalty, and customer value expansion.

### 7. What is the average cashier tenure by gender as of April 30, 2018?

| Gender | Average working days |
| --- | ---: |
| F | 1,870.13 |
| M | 1,636.67 |

Key insights:

- Female cashiers average 1,870.13 working days, while male cashiers average 1,636.67 working days.
- The tenure gap is about 233 days, or roughly 7.7 months, in favor of female cashiers.
- This may influence training cost, scheduling stability, and cashier productivity, but tenure alone does not prove performance.
- The workforce team should compare tenure with rolling revenue performance to see whether experience translates into higher sales throughput.
- The result should also be reviewed for headcount balance by gender, because averages can be distorted when one group has fewer employees.

### 8. Which catalog SKUs had no sales lines during the snapshot?

There are 0 unsold SKUs in the January-April 2018 snapshot.

Key insights:

- No catalog SKU is completely unsold in the January-April snapshot, so there is no immediate zero-sale clearance list.
- This is a positive catalog coverage signal: every product has at least some demand.
- Clearance decisions should move to a more nuanced definition, such as bottom-quartile units sold, low revenue per unit, poor margin, or high inventory age.
- The absence of zero-sale SKUs does not mean every product is healthy. It only means every product generated at least one sales line.
- The next useful SQL analysis would rank the slowest-selling products by category and compare them with list price.

### 9. What are monthly revenue and cumulative revenue across the snapshot?

| Month | Monthly revenue | Cumulative revenue |
| --- | ---: | ---: |
| 2018-01 | 1,030,735,897.00 | 1,030,735,897.00 |
| 2018-02 | 929,204,217.48 | 1,959,940,114.48 |
| 2018-03 | 1,032,200,775.73 | 2,992,140,890.21 |
| 2018-04 | 997,268,501.06 | 3,989,409,391.27 |

Key insights:

- The business generated USD 3.989B across the four-month snapshot.
- January and March are both above USD 1.03B, while February is the only month below USD 950M.
- March adds the largest monthly revenue and pushes cumulative revenue close to USD 3.0B by the end of Q1.
- April remains strong at USD 997.3M but does not fully match the January/March level.
- For executive reporting, monthly revenue explains trend direction, while cumulative revenue shows scale and progress toward period targets.

### 10. How do customers split into four spend quartiles?

| Segment | Customers | Total spend | Average spend per customer |
| --- | ---: | ---: | ---: |
| Highest spenders (top 25%) | 24,690 | 1,763,479,090.86 | 71,424.83 |
| Above-average spenders | 24,690 | 1,211,989,500.60 | 49,088.27 |
| Below-average spenders | 24,690 | 741,054,283.76 | 30,014.35 |
| Lowest spenders | 24,689 | 272,886,516.04 | 11,052.96 |

Key insights:

- The top 25% of customers generate USD 1.763B, equal to about 44.2% of snapshot revenue.
- The top two quartiles together generate about USD 2.975B, or roughly three quarters of total spend.
- Average spend falls sharply from USD 71.4K in the top quartile to USD 11.1K in the lowest quartile.
- Marketing should protect the highest-spend customers with retention and loyalty tactics because they carry a disproportionate share of revenue.
- The lowest two quartiles should not receive the same treatment. They need targeted activation, basket-building offers, or category-specific promotions to improve value.

### 11. What is each category's monthly revenue share?

Category mix is stable across the four months. Confections leads every month at about 12.8%-12.9% of revenue. Meat follows at about 11.3%-11.4%, and Poultry holds about 10.1%-10.2%. Shell fish has the lowest share at about 6.9%.

Key insights:

- Category share is stable across the four-month period, so the monthly revenue trend is not caused by a major category-mix swing.
- Confections is the largest category by share, staying around 12.8%-12.9% each month.
- Meat and Poultry consistently rank as major contributors, while Shell fish remains the smallest revenue-share category.
- Because category shares are steady, the board stacked-bar chart should emphasize stability and scale rather than volatility.
- Management should investigate absolute revenue changes by month, because share alone may hide a category growing or shrinking with the overall market.

### 12. What is each employee's best rolling 30-day revenue window?

The SQL file returns the best rolling 30-day revenue window for every employee. The top 5 are:

| Rank | Employee | Max rolling 30-day revenue | Window start |
| ---: | --- | ---: | --- |
| 1 | Devon Brewer | 44,213,466.69 | 2018-03-20 |
| 2 | Desiree Stuart | 44,004,941.06 | 2018-03-06 |
| 3 | Wendi Buckley | 43,909,613.91 | 2018-03-25 |
| 4 | Shelby Riddle | 43,885,407.81 | 2018-01-02 |
| 5 | Tonia Mc Millan | 43,872,357.63 | 2018-02-14 |

Key insights:

- Devon Brewer has the strongest rolling 30-day window at USD 44.21M starting March 20, 2018.
- Three of the top five employee windows start in March, matching the strongest revenue month in the snapshot.
- The top employee results are close together, so performance appears distributed across several strong cashiers rather than concentrated in one person.
- Workforce planning should protect high-performing employees during expected peak windows and ensure enough experienced coverage around March-like demand periods.
- A fair performance review should combine this revenue view with shift hours, store assignment, foot traffic, and transaction count.

### 13. Which product pairs are most frequently bought together in one invoice?

The dataset has 6,223,697 snapshot invoices and 0 multi-product invoices. Because `TransactionNumber` is unique per sales line, there are no valid same-invoice product pairs to rank.

Key insights:

- The snapshot has 6,223,697 invoices and 0 multi-product invoices, so no valid same-invoice product pairs exist.
- The SQL still includes the requested product-pair output, but it correctly returns zero rows because the required basket structure is absent.
- This is a data-model limitation, not a SQL failure. Bundle analysis needs a receipt or basket ID that can connect multiple product lines to one customer purchase.
- Creating product pairs from a proxy such as same customer and same day would inflate co-purchase signals and could mislead marketing.
- The correct recommendation is to fix transaction capture first, then rerun market-basket analysis once multi-product invoices are available.

## How To Reproduce

1. Open SQL Server Management Studio or Azure Data Studio.
2. Run `sql/00-create-database-and-schema.sql`.
3. In `sql/01-load-raw-csv-bulk-insert.sql`, set `@dataset_root` to the absolute path of this project's `source-data/` folder.
4. Run `sql/01-load-raw-csv-bulk-insert.sql`.
5. Run `sql/02-analytics-views.sql`.
6. Run `sql/04-validation-queries.sql`.
7. Run `sql/03-business-analysis-queries.sql`.

## Skills Demonstrated

- SQL Server schema design and CSV loading
- Raw-to-mart analytical modeling
- Joins, CTEs, aggregations, ranking, quartiles, and window functions
- Invoice-level AOV and repeat-customer analysis
- Customer segmentation and category mix analysis
- Rolling 30-day employee performance analysis
- Data-quality-aware business interpretation

## Limitations

- The analysis snapshot is January 1, 2018 through April 30, 2018.
- Rows outside the snapshot are excluded from snapshot-specific questions.
- Blank sales dates are excluded from trend analysis.
- `sales.TotalPrice` is unusable because it is zero in all processed rows.
- `TransactionNumber` is unique per sales line, so same-invoice product-pair analysis has no eligible multi-product invoices.
- The dataset appears synthetic and should be used for portfolio demonstration, not real commercial decisions.
