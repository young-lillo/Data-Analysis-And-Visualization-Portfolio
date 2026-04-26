# Social Media Marketing Performance Portfolio

This project turns social media content performance data into a marketing analytics dashboard for platform comparison, content strategy, posting-time optimization, hashtag effectiveness, video/live-stream interest, and organic-versus-sponsored performance.

Local dashboard: `http://localhost:3001/dashboard/2`

Local public dashboard: `http://localhost:3001/public/dashboard/b9f811ac-fd0a-49c3-b4b6-d4597cc04d13`

## Project Context

The dataset contains 5,600 social post records across 6 platforms, 8 regions, 5 content categories, 7 post types, and 18 main hashtags. The covered date range is `2024-01-01` to `2025-05-01`.

The project uses `CRISP-DM`, Python, PostgreSQL-compatible SQL, Docker, and Metabase. The data model is PostgreSQL-first so it can run locally and later move to Supabase with minimal changes.

## Goals

- compare platform and post-type performance by engagement, views, impressions, and CTR
- identify content categories that perform best by region
- find day and hour patterns that support posting-time optimization
- evaluate hashtag contribution to impressions, clicks, and engagement rate
- compare organic and sponsored content performance
- show where video and live-stream formats have stronger regional interest

## What Are the Steps to Do

### 1. Context, Goals, and Approach

I framed the portfolio as a content performance intelligence case, not a vanity-metric report. The dashboard answers which platform, content, timing, region, and promotion choices create stronger marketing outcomes.

I used `CRISP-DM` as the project structure:

- business understanding: define the marketing decisions the dashboard should support
- data understanding: inspect platform, region, content, hashtag, timing, engagement, views, clicks, and CTR fields
- data preparation: clean the workbook, standardize fields, derive KPI helpers, and build dashboard-ready exports
- modeling: create platform, region, content, hashtag, posting-time, video/live, and paid-versus-organic marts
- evaluation and deployment: seed PostgreSQL, build Metabase questions, and publish a local public dashboard

### 2. Data Preparation

The source workbook is included at [`docs/assets/user-files/social-media-content-performance-dataset.xlsx`](docs/assets/user-files/social-media-content-performance-dataset.xlsx). The prepared exports are under [`docs/assets/exports`](docs/assets/exports).

Tools used:

- [`tools/build-social-media-prepared-exports.py`](tools/build-social-media-prepared-exports.py) for workbook ingestion, cleaning, and mart generation
- [`postgres/sql/01-schema-and-load.sql`](postgres/sql/01-schema-and-load.sql) for schema creation and CSV loading
- [`postgres/sql/02-analytics-views.sql`](postgres/sql/02-analytics-views.sql) for dashboard-facing views
- [`docs/data-preparation.md`](docs/data-preparation.md) for the data contract and quality notes

What I did with the dataset:

- processed 5,600 post records
- added a stable `post_row_id` because `post_id` is not unique
- derived day-of-week, month, hour, and KPI efficiency fields
- flagged click-trackable, video, and live-stream rows
- built dimensions and marts for platform, region, content, hashtag, timing, and paid-versus-organic analysis
- documented known data risks such as partial click coverage and source-provided engagement totals

### 3. Data Visualize

I used Metabase to build a local dashboard backed by PostgreSQL views and prepared marts.

Tools used:

- [`docker-compose.yml`](docker-compose.yml) for local PostgreSQL and Metabase
- [`tools/create-metabase-dashboard.ps1`](tools/create-metabase-dashboard.ps1) for repeatable dashboard creation
- [`docs/visualization.md`](docs/visualization.md) for dashboard scope, validation status, and rebuild notes
- [`docs/publish.md`](docs/publish.md) for Supabase and hosted Metabase handoff

Dashboard sections:

- business-question guide
- platform overview
- post type performance
- regional category performance
- posting-time optimization
- hashtag effectiveness
- video and live-stream interest
- organic versus sponsored comparison
- key insights and suggested actions
- trackable post detail

The dashboard includes field-backed filters for `Platform`, `Region`, `Content Type`, and `Content Category`.

## How to Clone the Project

Current upstream source:

```bash
git clone https://github.com/young-lillo/data-visualization-skills.git
cd data-visualization-skills/projects/social-media-marketing-performance-portfolio
```

If this folder is published as its own repository later, the clone flow becomes:

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

## How to Deploy Locally

1. Install Python dependencies from [`requirements.txt`](requirements.txt).
2. Regenerate prepared exports if needed:

```powershell
python tools\build-social-media-prepared-exports.py
```

3. Start PostgreSQL and Metabase:

```powershell
docker compose up -d
```

4. Open Metabase at `http://localhost:3001`.
5. If you need to reseed the dashboard, run:

```powershell
.\tools\create-metabase-dashboard.ps1 -Username "you@example.com" -Password "your-password"
```

More detail: [`docs/publish.md`](docs/publish.md)

## Dashboard

Local dashboard:

- `http://localhost:3001/dashboard/2`
- `http://localhost:3001/public/dashboard/b9f811ac-fd0a-49c3-b4b6-d4597cc04d13`

## Insights / Learning

- `post_id` is not reliable as a row key because 600 duplicate IDs exist, so row-level analysis should use `post_row_id`.
- CTR and click analysis should stay limited to click-trackable rows because 3,740 rows are missing clicks and CTR.
- Engagement should be treated as a source-provided aggregate metric because it does not equal `likes + shares + comments`.
- The strongest dashboard story is content decision support: platform, region, content type, timing, and promotion type are more useful together than as isolated KPI cards.
- Metabase works well for this portfolio because it supports filterable stakeholder dashboards over PostgreSQL views and repeatable dashboard creation from script.
