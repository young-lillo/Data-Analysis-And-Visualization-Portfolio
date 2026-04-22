drop schema if exists public cascade;
create schema public;

create table dim_school (
  school_id text primary key,
  school_name text not null,
  municipality text
);

create table dim_student (
  student_id text primary key,
  date_of_birth date,
  gender text,
  school_id text references dim_school (school_id)
);

create table dim_assessment_type (
  assessment_type text primary key,
  assessment_group text,
  description text,
  assessment_cost_per_student numeric(10, 2)
);

create table dim_assessment_level (
  assessment_level_id text primary key,
  assessment_level text,
  level_grouping text,
  score_range text
);

create table fact_student_assessment (
  standard_score numeric(10, 2),
  assessment_level_id text references dim_assessment_level (assessment_level_id),
  student_assessment_id text primary key,
  student_id text references dim_student (student_id),
  assessment_type text references dim_assessment_type (assessment_type),
  assessment_date date,
  school_year_grade_class text,
  school_year text,
  toswrf_assessment_id text,
  towre_assessment_id text,
  semester text,
  grade_label text,
  school_id text references dim_school (school_id),
  gender text,
  date_of_birth date,
  school_name text,
  municipality text,
  assessment_group text,
  description text,
  assessment_cost_per_student numeric(10, 2),
  assessment_level text,
  level_grouping text,
  score_range text,
  grade_number integer,
  term_order integer,
  intervention_tier text,
  requires_intervention boolean,
  assessment_cost numeric(10, 2),
  below_average_flag boolean
);

create table fact_intervention_demand (
  school_id text references dim_school (school_id),
  school_name text,
  municipality text,
  school_year text,
  semester text,
  term_order integer,
  assessment_type text references dim_assessment_type (assessment_type),
  grade_number integer,
  total_students_tested integer,
  students_requiring_intervention integer,
  tier_2_students integer,
  tier_3_students integer,
  below_average_students integer,
  average_standard_score numeric(10, 4),
  assessment_cost_per_student numeric(10, 2),
  tier_2_teachers integer,
  tier_3_teachers integer,
  total_required_teachers integer,
  intervention_rate numeric(10, 4),
  total_assessment_cost numeric(10, 2)
);

create table fact_forecast_intervention_demand (
  school_id text references dim_school (school_id),
  school_name text,
  municipality text,
  assessment_type text references dim_assessment_type (assessment_type),
  grade_number integer,
  next_school_year text,
  next_semester text,
  baseline_school_year text,
  baseline_semester text,
  forecast_students_tested integer,
  forecast_students_requiring_intervention integer,
  forecast_tier_2_students integer,
  forecast_tier_3_students integer,
  forecast_tier_2_teachers integer,
  forecast_tier_3_teachers integer,
  forecast_total_teachers integer,
  assessment_cost_per_student numeric(10, 2),
  forecast_assessment_cost numeric(10, 2),
  forecast_method text
);

copy dim_school from '/seed/dim-school.csv' csv header;
copy dim_student from '/seed/dim-student.csv' csv header;
copy dim_assessment_type (
  assessment_group,
  assessment_type,
  description,
  assessment_cost_per_student
) from '/seed/dim-assessment-type.csv' csv header;
copy dim_assessment_level from '/seed/dim-assessment-level.csv' csv header;
copy fact_student_assessment (
  standard_score,
  assessment_level_id,
  student_assessment_id,
  student_id,
  assessment_type,
  assessment_date,
  school_year_grade_class,
  semester,
  school_year,
  toswrf_assessment_id,
  towre_assessment_id,
  grade_label,
  school_id,
  gender,
  date_of_birth,
  school_name,
  municipality,
  assessment_group,
  description,
  assessment_cost_per_student,
  assessment_level,
  level_grouping,
  score_range,
  grade_number,
  term_order,
  intervention_tier,
  requires_intervention,
  assessment_cost,
  below_average_flag
) from '/seed/fact-student-assessment.csv' csv header;
copy fact_intervention_demand from '/seed/fact-intervention-demand.csv' csv header;
copy fact_forecast_intervention_demand from '/seed/fact-forecast-intervention-demand.csv' csv header;

create index idx_fact_student_assessment_school_term on fact_student_assessment (school_year, semester, school_id, assessment_type, grade_number);
create index idx_fact_intervention_demand_school_term on fact_intervention_demand (school_year, semester, school_id, assessment_type, grade_number);
create index idx_fact_forecast_school on fact_forecast_intervention_demand (next_school_year, next_semester, school_id, assessment_type, grade_number);

create or replace view vw_fvsd_executive_overview as
select
  school_year,
  semester,
  assessment_type,
  count(*) as assessment_rows,
  round(avg(standard_score), 2) as avg_standard_score,
  sum(case when requires_intervention then 1 else 0 end) as intervention_students,
  round(avg(case when requires_intervention then 1.0 else 0.0 end), 4) as intervention_rate,
  sum(assessment_cost) as total_assessment_cost
from fact_student_assessment
group by 1, 2, 3;

create or replace view vw_fvsd_school_pressure as
select
  school_year,
  semester,
  school_id,
  school_name,
  municipality,
  sum(total_students_tested) as total_students_tested,
  sum(students_requiring_intervention) as students_requiring_intervention,
  sum(tier_2_students) as tier_2_students,
  sum(tier_3_students) as tier_3_students,
  sum(total_required_teachers) as total_required_teachers,
  round(sum(students_requiring_intervention)::numeric / nullif(sum(total_students_tested), 0), 4) as intervention_rate,
  sum(total_assessment_cost) as total_assessment_cost
from fact_intervention_demand
group by 1, 2, 3, 4, 5;

create or replace view vw_fvsd_grade_assessment_mix as
select
  school_year,
  semester,
  assessment_type,
  grade_number,
  sum(total_students_tested) as total_students_tested,
  sum(students_requiring_intervention) as students_requiring_intervention,
  round(sum(students_requiring_intervention)::numeric / nullif(sum(total_students_tested), 0), 4) as intervention_rate,
  round(avg(average_standard_score), 2) as avg_standard_score
from fact_intervention_demand
group by 1, 2, 3, 4;

create or replace view vw_fvsd_next_term_forecast as
select
  next_school_year,
  next_semester,
  school_id,
  school_name,
  municipality,
  assessment_type,
  sum(forecast_students_tested) as forecast_students_tested,
  sum(forecast_students_requiring_intervention) as forecast_students_requiring_intervention,
  sum(forecast_tier_2_students) as forecast_tier_2_students,
  sum(forecast_tier_3_students) as forecast_tier_3_students,
  sum(forecast_total_teachers) as forecast_total_teachers,
  sum(forecast_assessment_cost) as forecast_assessment_cost
from fact_forecast_intervention_demand
group by 1, 2, 3, 4, 5, 6;

create or replace view vw_fvsd_assessment_level_distribution as
select
  school_year,
  semester,
  term_order,
  coalesce(school_name, 'Unknown School') as school_name,
  assessment_level,
  count(*) as student_count,
  round(
    count(*)::numeric
    / nullif(sum(count(*)) over (
      partition by school_year, semester, coalesce(school_name, 'Unknown School')
    ), 0),
    4
  ) as pct_students
from fact_student_assessment
group by 1, 2, 3, 4, 5;

create or replace view vw_fvsd_assessment_type_distribution as
select
  school_year,
  semester,
  term_order,
  coalesce(school_name, 'Unknown School') as school_name,
  assessment_type,
  count(*) as student_count
from fact_student_assessment
group by 1, 2, 3, 4, 5;

create or replace view vw_fvsd_assessment_level_group_distribution as
select
  school_year,
  semester,
  term_order,
  coalesce(school_name, 'Unknown School') as school_name,
  level_grouping,
  count(*) as student_count,
  round(
    count(*)::numeric
    / nullif(sum(count(*)) over (
      partition by school_year, semester, coalesce(school_name, 'Unknown School')
    ), 0),
    4
  ) as pct_students
from fact_student_assessment
group by 1, 2, 3, 4, 5;

create or replace view vw_fvsd_winter_2023_2024_forecast as
select
  baseline_school_year,
  baseline_semester,
  next_school_year,
  next_semester,
  coalesce(school_name, 'Unknown School') as school_name,
  assessment_type,
  sum(forecast_tier_2_students) as forecast_tier_2_students,
  sum(forecast_tier_3_students) as forecast_tier_3_students,
  sum(forecast_tier_2_teachers) as forecast_tier_2_teachers,
  sum(forecast_tier_3_teachers) as forecast_tier_3_teachers,
  sum(forecast_assessment_cost) as forecast_assessment_cost
from fact_forecast_intervention_demand
where baseline_school_year = '2023 / 2024'
  and baseline_semester = 'Fall'
  and next_school_year = '2023 / 2024'
  and next_semester = 'Winter'
group by 1, 2, 3, 4, 5, 6;

create or replace view vw_fvsd_assessment_level_change as
with level_term as (
  select
    school_year,
    semester,
    term_order,
    assessment_level,
    count(*) as student_count
  from fact_student_assessment
  group by 1, 2, 3, 4
),
level_term_with_lag as (
  select
    school_year,
    semester,
    term_order,
    assessment_level,
    student_count,
    lag(student_count) over (
      partition by assessment_level
      order by school_year, term_order
    ) as previous_term_count,
    lag(student_count, 3) over (
      partition by assessment_level
      order by school_year, term_order
    ) as previous_year_same_term_count
  from level_term
)
select
  school_year,
  semester,
  term_order,
  assessment_level,
  student_count,
  previous_term_count,
  student_count - previous_term_count as change_vs_previous_term,
  round(
    (student_count - previous_term_count)::numeric
    / nullif(previous_term_count, 0),
    4
  ) as pct_change_vs_previous_term,
  previous_year_same_term_count,
  student_count - previous_year_same_term_count as change_vs_previous_year,
  round(
    (student_count - previous_year_same_term_count)::numeric
    / nullif(previous_year_same_term_count, 0),
    4
  ) as pct_change_vs_previous_year
from level_term_with_lag;

create or replace view vw_fvsd_average_score_trend as
select
  school_year,
  semester,
  term_order,
  school_year || ' - ' || semester as period,
  assessment_type,
  round(avg(standard_score), 2) as avg_standard_score,
  count(*) as assessment_rows
from fact_student_assessment
group by 1, 2, 3, 4, 5;

create or replace view vw_fvsd_term_metrics as
select
  fid.school_year,
  fid.semester,
  fid.term_order,
  case
    when fid.school_year = '2021 / 2022' then 2021
    when fid.school_year = '2022 / 2023' then 2022
    when fid.school_year = '2023 / 2024' then 2023
    else 0
  end as academic_year_start,
  (case
    when fid.school_year = '2021 / 2022' then 2021
    when fid.school_year = '2022 / 2023' then 2022
    when fid.school_year = '2023 / 2024' then 2023
    else 0
  end * 10) + fid.term_order as academic_period_index,
  fid.school_id,
  fid.school_name,
  fid.municipality,
  fid.assessment_type,
  dat.assessment_group,
  sum(fid.total_students_tested)           as total_students_tested,
  sum(fid.students_requiring_intervention) as students_requiring_intervention,
  sum(fid.tier_2_students)                 as tier_2_students,
  sum(fid.tier_3_students)                 as tier_3_students,
  sum(fid.total_required_teachers)         as total_required_teachers,
  sum(fid.total_assessment_cost)           as total_assessment_cost,
  round(sum(fid.students_requiring_intervention)::numeric
        / nullif(sum(fid.total_students_tested), 0), 4) as intervention_rate,
  round(avg(fsa.standard_score), 2)        as avg_standard_score
from fact_intervention_demand fid
join dim_assessment_type dat on dat.assessment_type = fid.assessment_type
left join (
  select school_id, school_year, semester, assessment_type, avg(standard_score) as standard_score
  from fact_student_assessment
  group by 1, 2, 3, 4
) fsa on fsa.school_id       = fid.school_id
      and fsa.school_year    = fid.school_year
      and fsa.semester       = fid.semester
      and fsa.assessment_type = fid.assessment_type
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;

create or replace view vw_fvsd_term_comparison as
select
  school_year, semester, term_order, academic_period_index,
  school_id, school_name, assessment_type, assessment_group,
  total_students_tested,
  students_requiring_intervention,
  intervention_rate,
  avg_standard_score,
  total_required_teachers,
  lag(total_students_tested)           over w as prev_students_tested,
  lag(students_requiring_intervention) over w as prev_students_requiring_intervention,
  lag(intervention_rate)               over w as prev_intervention_rate,
  lag(avg_standard_score)              over w as prev_avg_score,
  lag(total_required_teachers)         over w as prev_required_teachers,
  students_requiring_intervention
    - lag(students_requiring_intervention) over w as delta_intervention_students,
  round(
    (students_requiring_intervention
      - lag(students_requiring_intervention) over w)::numeric
    / nullif(lag(students_requiring_intervention) over w, 0),
    4
  ) as pct_delta_intervention,
  avg_standard_score
    - lag(avg_standard_score) over w as delta_avg_score
from vw_fvsd_term_metrics
window w as (
  partition by school_id, assessment_type
  order by academic_period_index
);

create or replace view vw_fvsd_yoy_same_term as
select
  cur.school_year,
  cur.semester,
  cur.school_id,
  cur.school_name,
  cur.assessment_type,
  cur.assessment_group,
  cur.students_requiring_intervention    as curr_intervention_students,
  prior.students_requiring_intervention  as prior_year_intervention_students,
  cur.students_requiring_intervention
    - prior.students_requiring_intervention as yoy_delta_intervention,
  cur.avg_standard_score                 as curr_avg_score,
  prior.avg_standard_score               as prior_year_avg_score,
  round(
    (cur.avg_standard_score - prior.avg_standard_score)::numeric
    / nullif(prior.avg_standard_score, 0),
    4
  ) as yoy_pct_score_change
from vw_fvsd_term_metrics cur
join vw_fvsd_term_metrics prior
  on  prior.school_id        = cur.school_id
  and prior.assessment_type  = cur.assessment_type
  and prior.semester         = cur.semester
  and prior.academic_year_start = cur.academic_year_start - 1;

create or replace view vw_fvsd_forecast_baseline_bridge as
select
  f.baseline_school_year,
  f.baseline_semester,
  f.next_school_year,
  f.next_semester,
  f.school_id,
  coalesce(f.school_name, 'Unknown School') as school_name,
  f.municipality,
  dat.assessment_group,
  f.assessment_type,
  sum(f.forecast_students_requiring_intervention) as forecast_students_requiring_intervention,
  sum(f.forecast_tier_2_students)                 as forecast_tier_2_students,
  sum(f.forecast_tier_3_students)                 as forecast_tier_3_students,
  sum(f.forecast_tier_2_teachers)                 as forecast_tier_2_teachers,
  sum(f.forecast_tier_3_teachers)                 as forecast_tier_3_teachers,
  sum(f.forecast_total_teachers)                  as forecast_total_teachers,
  sum(f.forecast_assessment_cost)                 as forecast_assessment_cost
from fact_forecast_intervention_demand f
join dim_assessment_type dat on dat.assessment_type = f.assessment_type
group by 1, 2, 3, 4, 5, 6, 7, 8, 9;
