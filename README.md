# Data Analysis and Visualization Portfolio

This repository collects four end-to-end analytics portfolio projects. Each folder contains the project README, documentation, data-preparation logic, dashboard assets, and deployment notes needed to understand or reproduce the work.

## Portfolio Projects

### [Banking Transaction Data Analytics Challenge](Banking%20Transaction%20Data%20Analytics%20Challenge)

Banking analytics project turning 20,000 synthetic transaction records into a Power BI dashboard for customer segmentation, fee revenue, channel behavior, branch geography, risk-proxy signals, and offer alignment.

Included materials:

- USD-normalized prepared transaction data and historical EUR/USD rate audit table
- Power BI star schema with fact and dimension CSVs
- DAX measure definitions, Power Query notes, and dashboard build guide
- Power BI `.pbix` files, PDF export, and dashboard screenshots

Live dashboard: [Banking Transaction Data Analytics Challenge](https://app.powerbi.com/view?r=eyJrIjoiNjgyMTFlMGUtZGI1YS00NGMyLTk0ZmEtODUxODRlMzE2NWYzIiwidCI6IjM3MGZiM2I4LTMzMDYtNDg5MC05MDYzLWNjMDhiZTc4ODI1NyIsImMiOjEwfQ%3D%3D)

### [Airbnb Global Listings Reviews Analytics](Airbnb%20Global%20Listings%20Reviews%20Analytics)

Hospitality analytics project using global Airbnb listings and historical review activity across 10 cities. The work focuses on market comparison, pricing signals, seasonality, COVID recovery, and traveler value-for-money.

Included materials:

- Python and SQL analysis scripts for profiling, currency normalization, and dashboard mart generation
- Prepared CSV marts and Metabase SQL question definitions
- Dashboard screenshots and a Metabase dashboard specification
- Documentation for project goals, data preparation, visualization design, publishing, and deployment

Live dashboard: [Airbnb Global Listings Reviews Analytics](https://data.khanh-pham.work/public/dashboard/99008e31-dc72-4fc5-8fe0-bb70326eb19b)

### [FVSD Literacy Intervention Portfolio](FVSD%20Literacy%20Intervention%20Portfolio)

Education analytics project turning FVSD literacy assessment data into an intervention-planning dashboard for school leaders. The work frames literacy data as an operations problem covering support tiers, staffing demand, cost, and next-term planning pressure.

Included materials:

- Source workbook and reproducible Python preparation script
- PostgreSQL schema, load script, and analytics views
- Local Docker setup for PostgreSQL and Metabase
- Dashboard automation script, screenshot path, and documentation for preparation, visualization, and deployment

Live dashboard: [FVSD Literacy Intervention Dashboard](https://data.khanh-pham.work/public/dashboard/3115be47-ce51-4585-b045-d350a25a9b0d)

### [Social Media Marketing Performance Portfolio](Social%20Media%20Marketing%20Performance%20Portfolio)

Marketing analytics project turning social content performance data into a Metabase dashboard for platform comparison, content strategy, posting-time optimization, hashtag effectiveness, and organic-versus-sponsored performance.

Included materials:

- Source workbook and reproducible Python preparation script
- PostgreSQL schema, load script, and analytics views
- Local Docker setup for PostgreSQL and Metabase
- Dashboard automation script and documentation for preparation, visualization, and publish handoff

Live dashboard: [Social Media Marketing Performance](https://data.khanh-pham.work/public/dashboard/7781e3d8-f806-413b-8d57-75b014d5b734)

## Skills Demonstrated

- Data cleaning and preparation with Python
- Analytical modeling with SQL and PostgreSQL
- Dashboard design with Power BI and Metabase
- CRISP-DM project framing
- Stakeholder-focused reporting and documentation
- Reproducible project packaging for portfolio review

## Repository Structure

```text
.
|-- Banking Transaction Data Analytics Challenge/
|   |-- README.md
|   |-- docs/
|   |-- powerbi/
|   `-- tools/
|-- Airbnb Global Listings Reviews Analytics/
|   |-- README.md
|   |-- docs/
|   `-- tools/
|-- FVSD Literacy Intervention Portfolio/
|   |-- README.md
|   |-- docs/
|   |-- postgres/
|   `-- tools/
`-- Social Media Marketing Performance Portfolio/
    |-- README.md
    |-- docs/
    |-- postgres/
    `-- tools/
```

Start with the README inside each project folder for project-specific setup, data preparation, dashboard, and deployment details.
