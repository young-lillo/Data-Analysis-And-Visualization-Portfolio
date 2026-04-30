# Data Analysis and Visualization Portfolio

This repository collects three end-to-end analytics portfolio projects. Each folder contains the project README, documentation, data-preparation logic, dashboard assets, and deployment notes needed to understand or reproduce the work.

## Portfolio Projects

### [Airbnb Global Listings Reviews Analytics](Airbnb%20Global%20Listings%20Reviews%20Analytics)

Hospitality analytics project using global Airbnb listings and historical review activity across 10 cities. The work focuses on market comparison, pricing signals, seasonality, COVID recovery, and traveler value-for-money.

Included materials:

- Python and SQL analysis scripts for profiling, currency normalization, and dashboard mart generation
- Prepared CSV marts and Metabase SQL question definitions
- Dashboard screenshots and a Metabase dashboard specification
- Documentation for project goals, data preparation, visualization design, publishing, and deployment

Live dashboard: [Airbnb Global Listings Reviews Analytics](https://data.youngllilo.works/public/dashboard/99008e31-dc72-4fc5-8fe0-bb70326eb19b)

### [FVSD Literacy Intervention Portfolio](FVSD%20Literacy%20Intervention%20Portfolio)

Education analytics project turning FVSD literacy assessment data into an intervention-planning dashboard for school leaders. The work frames literacy data as an operations problem covering support tiers, staffing demand, cost, and next-term planning pressure.

Included materials:

- Source workbook and reproducible Python preparation script
- PostgreSQL schema, load script, and analytics views
- Local Docker setup for PostgreSQL and Metabase
- Dashboard automation script, screenshot path, and documentation for preparation, visualization, and deployment

Live dashboard: [FVSD Literacy Intervention Dashboard](https://data.youngllilo.works/public/dashboard/3115be47-ce51-4585-b045-d350a25a9b0d)

### [Social Media Marketing Performance Portfolio](Social%20Media%20Marketing%20Performance%20Portfolio)

Marketing analytics project turning social content performance data into a Metabase dashboard for platform comparison, content strategy, posting-time optimization, hashtag effectiveness, and organic-versus-sponsored performance.

Included materials:

- Source workbook and reproducible Python preparation script
- PostgreSQL schema, load script, and analytics views
- Local Docker setup for PostgreSQL and Metabase
- Dashboard automation script and documentation for preparation, visualization, and publish handoff

Live dashboard: [Social Media Marketing Performance](https://data.youngllilo.works/public/dashboard/7781e3d8-f806-413b-8d57-75b014d5b734)

## Skills Demonstrated

- Data cleaning and preparation with Python
- Analytical modeling with SQL and PostgreSQL
- Dashboard design and automation with Metabase
- CRISP-DM project framing
- Stakeholder-focused reporting and documentation
- Reproducible project packaging for portfolio review

## Repository Structure

```text
.
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
