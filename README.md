# FVSD Literacy Intervention Portfolio

This project turns FVSD literacy assessment data into an intervention-planning dashboard for school leaders.

Live dashboard: [Public dashboard](https://data.youngllilo.works/public/dashboard/3115be47-ce51-4585-b045-d350a25a9b0d)

## Project Context

Fort Vermilion School Division is a public school division in Northwest Alberta, Canada. This portfolio follows a real planning workflow:

`student assessment results -> proficiency classification -> intervention decisions -> staffing and cost forecasting`

The project uses the FVSD literacy assessment workbook, prepares analytics-ready tables, loads them into PostgreSQL, and presents decision-ready views in Metabase. The case is framed as an operations and planning problem, not just a score-reporting exercise.

## Goals

- identify which schools, grades, and terms create the highest literacy intervention demand
- translate assessment scores into Tier 2 and Tier 3 support needs
- estimate staffing load using explicit intervention ratios
- show assessment-program cost and forecast next-term pressure points
- present the work as a portfolio-ready analytics case using `CRISP-DM`, `PostgreSQL`, and `Metabase`

## What Are the Steps to Do

### 1. Context, Goals, and Approach

I framed the portfolio around a real education-planning question: how FVSD can use recurring literacy assessments to identify students needing support, estimate intervention demand, and forecast staffing and cost impact early enough to act.

I used `CRISP-DM` as the project structure:

- business understanding: define the intervention-planning problem, not just score reporting
- data understanding: inspect the workbook structure, table grain, date coverage, assessment types, and school-year coverage
- data preparation: convert the raw workbook into clean tables and reusable analytics views
- modeling: derive intervention tiers, staffing demand, testing cost, and forecast metrics
- evaluation and deployment: publish the dashboard in `Metabase` for decision support

### 2. Data Preparation

The source dataset is the FVSD literacy workbook in [`docs/Education_Management_Dataset.xlsx`](docs/Education_Management_Dataset.xlsx). To make it ready for visualization, I built a preparation layer with Python, SQL, and PostgreSQL.

Tools used:

- [`tools/build-fvsd-prepared-exports.py`](tools/build-fvsd-prepared-exports.py) for workbook ingestion, cleaning, and export generation
- [`postgres/sql/01-schema-and-load.sql`](postgres/sql/01-schema-and-load.sql) for schema creation, loading logic, and analytics views
- [`docs/data-preparation.md`](docs/data-preparation.md) for the data contract and preparation notes

What I did with the dataset:

- validated the workbook structure across schools, students, teachers, tests, grading groups, and test details
- standardized key fields such as school year, term, grade, assessment type, and standard score
- mapped raw assessment results into intervention logic
- derived `Tier 2`, `Tier 3`, and `No Intervention` classifications from score thresholds
- aggregated prepared data into dashboard-ready tables and views for school, grade, term, and assessment analysis
- created forecast-oriented metrics such as intervention demand, teacher demand, and assessment-program cost

This preparation step turned the raw Excel workbook into a reproducible analytics layer that can be loaded into PostgreSQL and queried by Metabase.

### 3. Data Visualize

I used `Metabase` to build a dashboard that answers the portfolio goals through stakeholder-friendly questions, filters, and drilldowns.

Tools used:

- [`tools/create-metabase-dashboard.ps1`](tools/create-metabase-dashboard.ps1) for repeatable dashboard creation and update
- [`docs/visualization.md`](docs/visualization.md) for dashboard scope and card planning
- [`docker-compose.yml`](docker-compose.yml) to run PostgreSQL and Metabase locally

How the dashboard was set up to solve the goals:

- executive views summarize assessment coverage, proficiency distribution, and overall intervention pressure
- intervention views show where Tier 2 and Tier 3 demand is concentrated by school, grade, term, and assessment type
- staffing and cost views convert student need into required teacher count and forecast budget impact
- school-level drilldowns allow one-school analysis without changing the underlying data model
- insight cards translate chart outputs into planning implications so the dashboard tells a portfolio story, not just a collection of visuals

## How to Clone the Project

```bash
git clone https://github.com/young-lillo/Data-Analysis-And-Visualization-Portfolio.git
cd Data-Analysis-And-Visualization-Portfolio
```

## Screenshot Dashboard

The live dashboard is available here:

- [FVSD Literacy Intervention Dashboard](https://data.youngllilo.works/public/dashboard/3115be47-ce51-4585-b045-d350a25a9b0d)

Recommended screenshot path for GitHub presentation:

- `docs/assets/screenshots/overview.png`

## Insights / Learning

- The strongest story is not raw score reporting. The stronger analytics angle is resource planning under literacy risk.
- `CRISP-DM` fits the project well because the work starts from a business decision and ends in deployment-ready decision support.
- Forecasting should stay pragmatic and scenario-driven. This dataset supports planning better than aggressive predictive claims.
- Teacher-demand metrics should be explained as required staffing load, not confirmed staffing availability.
- Metabase is a practical choice for this portfolio because it supports stakeholder-friendly dashboards with lower operational overhead than a heavier BI stack.
