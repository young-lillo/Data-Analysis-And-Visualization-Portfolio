# Data Preparation

## Goal

Prepare a trusted analytics surface for the FVSD portfolio and make it directly usable by Metabase.

## Inputs

- Source workbook: `docs/Education_Management_Dataset.xlsx`
- Source sheets: `School`, `Students`, `Test Details`, `Grading Groups`, `Tests`
- Project contract: `docs/project-plan.md`

## Executed Steps

1. Copied the source workbook into the project docs tree for local reproducibility.
2. Built reproducible exports with [build-fvsd-prepared-exports.py](../tools/build-fvsd-prepared-exports.py).
3. Normalized entity names to snake_case and aligned keys across sheets.
4. Removed student names from the analytics dimension to avoid exposing unnecessary student identity fields in dashboard-ready tables.
5. Joined tests to students, schools, assessment types, and assessment level metadata.
6. Derived `grade_number`, `intervention_tier`, `requires_intervention`, `below_average_flag`, and assessment cost metrics.
7. Aggregated intervention demand to school / year / term / assessment / grade grain.
8. Built a simple next-term forecast table using a weighted latest-plus-history method.

## Prepared Outputs

Location: `docs/assets/exports/`

- `dim-school.csv`
- `dim-student.csv`
- `dim-assessment-type.csv`
- `dim-assessment-level.csv`
- `fact-student-assessment.csv`
- `fact-intervention-demand.csv`
- `fact-forecast-intervention-demand.csv`
- `data-preparation-summary.json`
- `01-analysis.sql`

## Validation Summary

From `data-preparation-summary.json`:

- Schools: `21`
- Students: `6,392`
- Assessment rows: `44,483`
- Intervention demand segments: `2,111`
- Forecast segments: `385`
- Unmatched `student_id` in tests: `0`
- Unmatched `assessment_level_id` in tests: `0`
- Duplicate `student_assessment_id`: `0`
- Students with orphan `school_id` values in `Students`: `661`
- Missing `school_id` in prepared fact after school validation: `21`
- Missing parsed grades: `0`
- Date range: `2021-09-02` to `2023-11-30`

## Trusted Grain

- `fact-student-assessment.csv`
  One student assessment attempt per row.
- `fact-intervention-demand.csv`
  One row per school, school year, semester, assessment type, and grade.
- `fact-forecast-intervention-demand.csv`
  One row per school, assessment type, and grade for the next forecasted term.

## Derived Business Logic

- `Tier 3`: `standard_score < 80`
- `Tier 2`: `80 <= standard_score < 90`
- `No Intervention`: `standard_score >= 90`
- `tier_2_teachers = ceil(tier_2_students / 10)`
- `tier_3_teachers = ceil(tier_3_students / 5)`
- `forecast_method = 0.6 * latest segment + 0.4 * seasonal-or-overall history`

## Data Risks

- `Students` contains `661` rows whose `school_id` does not exist in the `School` sheet.
  These keys are nulled during preparation so PostgreSQL seed constraints can hold.
- `Teachers` was intentionally excluded from staffing-capacity modeling.
  The workbook shape looks like course-assignment rows, not a clean intervention staffing supply table.
- `2023 / 2024` is partial in the current workbook because the latest observed assessment date is `2023-11-30`.
- Forecast output is planning-oriented and should not be presented as a high-confidence predictive model.

## Hand-off Contract For Visualization

Metabase should treat the following as canonical sources:

- `fact_intervention_demand`
- `fact_forecast_intervention_demand`
- `vw_fvsd_executive_overview`
- `vw_fvsd_school_pressure`
- `vw_fvsd_grade_assessment_mix`
- `vw_fvsd_next_term_forecast`
- `vw_fvsd_assessment_level_distribution`
- `vw_fvsd_assessment_type_distribution`
- `vw_fvsd_assessment_level_group_distribution`
- `vw_fvsd_winter_2023_2024_forecast`
- `vw_fvsd_assessment_level_change`
- `vw_fvsd_average_score_trend`
