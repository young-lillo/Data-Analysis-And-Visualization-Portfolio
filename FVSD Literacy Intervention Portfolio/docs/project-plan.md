# FVSD Literacy Intervention Portfolio - Project Plan

## Confirmed Decisions

- Framework: `CRISP-DM`
- Goal Tier: `Advanced`
- Visualization Tool: `Metabase`
- Deploy Target: `VPS`

## User Context

FVSD is a public school division in Northwest Alberta, Canada. The portfolio case follows a real operating workflow:

`student assessment results -> proficiency classification -> intervention decisions -> staffing and cost forecasting`

The output should be a portfolio-grade analytics project built from the provided Excel workbook and framed around real planning decisions for school leaders.

## Dataset Surface

Source file: `\bundle\docs`

Observed workbook structure:

- `School`: 21 schools with municipality metadata
- `Students`: 6,392 students with DOB, gender, school mapping
- `Teachers`: 11,980 teacher-course-school-year rows
- `Tests`: 44,483 assessment records
- `Grading Groups`: 7 proficiency bands with grouped rollup
- `Test Details`: 3 assessment types and per-student assessment cost

Observed analytical grain:

- Fact grain candidate: one student assessment attempt per row in `Tests`
- Time span: `2021-09-02` to `2023-11-30`
- Terms: `Fall`, `Winter`, `Spring`
- Assessment types: `TOSREC`, `TOWRE`, `TOSWRF`
- School years present: `2021 / 2022`, `2022 / 2023`, `2023 / 2024`

## Problem Interpretation

This is not only a score-reporting dataset. The stronger portfolio angle is resource planning under literacy risk.

Core business question:

How can FVSD use recurring literacy assessments to identify students needing support, estimate intervention load by school and term, and forecast staffing and budget impact early enough to act?

Secondary analytical questions:

1. Which schools, grades, and terms generate the highest intervention demand?
2. How does risk concentration differ by assessment type, school year, and proficiency grouping?
3. What staffing load emerges under the stated intervention ratios?
4. What cost burden comes from test administration versus intervention staffing demand?
5. Where are the likely next-term pressure points if current patterns continue?

## Framework Recommendation

Chosen framework: `CRISP-DM`

Why it fits:

- The portfolio is decision-first, not pipeline-first
- The strongest narrative is business understanding -> data understanding -> preparation -> modeling -> evaluation -> deployment
- Forecasting here is a planning model inside an analytics narrative, not a standalone MLOps system

Planned CRISP-DM flow:

1. Business understanding
   Translate literacy assessments into intervention and staffing decisions.
2. Data understanding
   Validate entity coverage, term coverage, level mapping, and score distribution.
3. Data preparation
   Build a cleaned assessment mart plus intervention/staffing logic tables.
4. Modeling
   Derive intervention tiers, staffing demand, cost metrics, and forecast views.
5. Evaluation
   Check whether outputs support school-level planning and explainable decision-making.
6. Deployment
   Publish an interactive Metabase portfolio on the VPS.

## Recommended Visualization Path

Chosen tool: `Metabase`

## Recommended Data Model

Target warehouse shape for downstream work:

- `dim_school`
  School ID, school name, municipality
- `dim_student`
  Student ID, gender, DOB, age band, school ID
- `dim_assessment_type`
  Assessment type, assessment group, description, per-student test cost
- `dim_assessment_level`
  Assessment level ID, level, grouping, score range
- `fact_student_assessment`
  Student assessment ID, student ID, assessment type, date, term, school year, grade, standard score, assessment level ID
- `fact_intervention_demand`
  Derived table at school-year-term-grade-assessment level with tier counts, required teachers, and estimated cost
- `fact_forecast_intervention_demand`
  Derived forecasting/scenario table for next-term staffing and budget outlook

Recommended derived fields:

- `intervention_tier`
  `Tier 3` if score `< 80`
  `Tier 2` if score `80-89`
  `No Intervention` otherwise
- `students_requiring_intervention`
- `tier_2_teacher_demand = ceil(tier_2_students / 10)`
- `tier_3_teacher_demand = ceil(tier_3_students / 5)`
- `assessment_cost = test_cost_per_student`
- `total_assessment_cost`
- `intervention_pressure_index`
- `next_term_forecast_students`
- `next_term_forecast_teachers`
- `next_term_forecast_budget`

## Analytical Deliverables

The dashboard should answer these portfolio questions:

1. Assessment coverage and score distribution by school year, term, grade, and test type
2. Below-average concentration by school, grade, and municipality
3. Tier 2 and Tier 3 intervention demand by school and term
4. Required teacher count under intervention ratios
5. Assessment program cost by school year and assessment type
6. Forecast of next-term intervention load and staffing need
7. Scenario analysis for staffing ratio or score-threshold sensitivity

Recommended dashboard sections:

- Executive Overview
- Assessment Performance
- Intervention Demand
- Staffing Forecast
- Cost and Budget Impact
- School Deep Dive
- Scenario Explorer

## Expected SQL and Python Depth

SQL depth: `medium to high`

- joins across 5-6 source entities
- reusable models/views for intervention logic
- aggregation by school, year, term, grade, test type
- forecasting-ready feature tables

Python depth: `medium`

- workbook ingestion and cleaning
- score band parsing and validation
- forecasting prototype if SQL-only forecasting is too weak
- export of cleaned tables to database-ready CSV or direct load artifacts

## Forecasting Approach

Use a pragmatic portfolio-safe approach first:

1. Build baseline descriptive trends by school, term, grade, and assessment type
2. Forecast next-term intervention demand using recent trend and seasonality-aware comparisons where possible
3. Convert forecasted intervention counts into teacher demand and budget impact
4. Add scenario toggles for staffing ratios and threshold assumptions

Preferred first forecasting methods:

- rolling trend baseline
- prior-term / prior-year seasonal comparison
- optional simple regression at school-assessment level if data stability supports it

Avoid overclaiming predictive accuracy. This dataset supports planning scenarios better than high-confidence predictive modeling.

## Data Quality and Validation Focus

- school ID integrity across `School`, `Students`, `Teachers`
- assessment level ID mapping completeness in `Tests`
- duplicate student assessment rows
- impossible or missing standard scores
- inconsistent grade labels and school-year parsing
- term/date consistency
- teacher table grain, because it appears course-level rather than pure teacher headcount

Critical caveat:

`Teachers` likely does not directly equal intervention staffing capacity. It appears to be teacher-course assignment data. Use it for context, not as a clean staffing supply table, unless a later validation proves otherwise.

## Risks

- Forecasting credibility may drop if school-term slices are too sparse
- Teacher data may not support actual available-staff calculations
- `2023 / 2024` may be partial because observed max assessment date is `2023-11-30`

## Assumptions

- `Standard Score` is the main metric used for intervention assignment
- Intervention logic applies uniformly across schools and assessment types
- Assessment costs from `Test Details` are per student attempt
- Teacher demand in the portfolio means required staffing load, not confirmed staff availability
- Forecasting target is planning support, not audited financial budgeting
