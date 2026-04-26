-- FVSD Metabase starter questions

-- 1. Executive trend by term and assessment type
select
  school_year,
  semester,
  assessment_type,
  assessment_rows,
  avg_standard_score,
  intervention_students,
  intervention_rate,
  total_assessment_cost
from vw_fvsd_executive_overview
order by school_year, case semester when 'Fall' then 1 when 'Winter' then 2 when 'Spring' then 3 end, assessment_type;

-- 2. School pressure ranking
select
  school_year,
  semester,
  school_name,
  municipality,
  total_students_tested,
  students_requiring_intervention,
  tier_2_students,
  tier_3_students,
  total_required_teachers,
  intervention_rate,
  total_assessment_cost
from vw_fvsd_school_pressure
order by school_year desc, semester, total_required_teachers desc, students_requiring_intervention desc;

-- 3. Grade and assessment risk mix
select
  school_year,
  semester,
  assessment_type,
  grade_number,
  total_students_tested,
  students_requiring_intervention,
  intervention_rate,
  avg_standard_score
from vw_fvsd_grade_assessment_mix
order by school_year, semester, assessment_type, grade_number;

-- 4. Next-term staffing forecast
select
  next_school_year,
  next_semester,
  school_name,
  municipality,
  assessment_type,
  forecast_students_tested,
  forecast_students_requiring_intervention,
  forecast_tier_2_students,
  forecast_tier_3_students,
  forecast_total_teachers,
  forecast_assessment_cost
from vw_fvsd_next_term_forecast
order by next_school_year, next_semester, forecast_total_teachers desc, forecast_students_requiring_intervention desc;
