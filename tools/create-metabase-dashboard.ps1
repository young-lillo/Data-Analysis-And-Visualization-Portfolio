param(
  [string]$BaseUrl = "http://localhost:3000",
  [string]$Username,
  [string]$Password,
  [int]$DatabaseId = 2,
  [int]$CollectionId = 4,
  [int]$DashboardId = 0
)

$ErrorActionPreference = "Stop"

function Invoke-Mb {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [hashtable]$Headers = @{}
  )
  $callArgs = @{
    Uri     = "$BaseUrl$Path"
    Method  = $Method
    Headers = $Headers
  }
  if ($null -ne $Body) {
    $callArgs.ContentType = "application/json"
    $callArgs.Body = ($Body | ConvertTo-Json -Depth 20 -Compress)
  }
  Invoke-RestMethod @callArgs
}

function New-NativeCard {
  param(
    [string]$Name,
    [string]$Description,
    [string]$Display,
    [string]$Query,
    [hashtable]$TemplateTags = @{},
    [hashtable]$VizSettings  = @{}
  )
  $body = @{
    name                   = $Name
    description            = $Description
    display                = $Display
    visualization_settings = $VizSettings
    collection_id          = $CollectionId
    dataset_query          = @{
      type     = "native"
      database = $DatabaseId
      native   = @{
        query           = $Query
        "template-tags" = $TemplateTags
      }
    }
  }
  Invoke-Mb -Method Post -Path "/api/card" -Body $body -Headers $script:Auth
}

# ------------------------------------------------------------------
# Auth
# ------------------------------------------------------------------
$session = Invoke-Mb -Method Post -Path "/api/session" -Body @{
  username = $Username
  password = $Password
}
$script:Auth = @{ "X-Metabase-Session" = $session.id }

# ------------------------------------------------------------------
# Dashboard shell
# ------------------------------------------------------------------
$dashboardName        = "FVSD Literacy Intervention Planning"
$dashboardDescription = "Assessment results, intervention demand, staffing forecasts, and cost analysis for FVSD school planning. Filter by school year, semester, or school at the top of the page."

if ($DashboardId -gt 0) {
  $dashboard = [pscustomobject]@{
    id            = $DashboardId
    name          = $dashboardName
    description   = $dashboardDescription
    collection_id = $CollectionId
  }
} else {
  $dashboard = Invoke-Mb -Method Post -Path "/api/dashboard" -Body @{
    name          = $dashboardName
    description   = $dashboardDescription
    collection_id = $CollectionId
  } -Headers $script:Auth
}

# ------------------------------------------------------------------
# Dashboard-level filter parameters
# ------------------------------------------------------------------
$paramSchoolYear = @{
  id      = "school_year_filter"
  type    = "string/="
  name    = "School Year"
  slug    = "school_year"
  default = $null
}
$paramSemester = @{
  id      = "semester_filter"
  type    = "string/="
  name    = "Semester"
  slug    = "semester"
  default = $null
}
$paramSchool = @{
  id      = "school_name_filter"
  type    = "string/="
  name    = "School"
  slug    = "school_name"
  default = $null
}

# Template-tags for filterable cards
$filterTags = @{
  school_year = @{
    id             = "school_year_tag"
    name           = "school_year"
    "display-name" = "School Year"
    type           = "text"
  }
  semester = @{
    id             = "semester_tag"
    name           = "semester"
    "display-name" = "Semester"
    type           = "text"
  }
  school_name = @{
    id             = "school_name_tag"
    name           = "school_name"
    "display-name" = "School"
    type           = "text"
  }
}

function New-ParamMappings {
  param(
    [int]$CardId,
    [string[]]$Tags
  )
  [System.Collections.Generic.List[hashtable]]$mappings = @()
  foreach ($tag in $Tags) {
    switch ($tag) {
      "school_year" {
        $mappings.Add(@{
          parameter_id = "school_year_filter"
          card_id      = $CardId
          target       = @("variable", @("template-tag", "school_year"))
        })
      }
      "semester" {
        $mappings.Add(@{
          parameter_id = "semester_filter"
          card_id      = $CardId
          target       = @("variable", @("template-tag", "semester"))
        })
      }
      "school_name" {
        $mappings.Add(@{
          parameter_id = "school_name_filter"
          card_id      = $CardId
          target       = @("variable", @("template-tag", "school_name"))
        })
      }
    }
  }
  return ,$mappings.ToArray()
}

# ------------------------------------------------------------------
# Reusable viz-settings helpers
# ------------------------------------------------------------------

# Stacked bar: x=col0, series=col1, y=col2
function VizStackedBar {
  param([string]$XCol, [string]$SeriesCol, [string]$YCol)
  return @{
    "graph.dimensions"  = @($XCol, $SeriesCol)
    "graph.metrics"     = @($YCol)
    "stackable.stack_type" = "stacked"
    "graph.x_axis.title_text" = $XCol
  }
}

# 100% stacked bar
function VizNormalizedBar {
  param([string]$XCol, [string]$SeriesCol, [string]$YCol)
  return @{
    "graph.dimensions"     = @($XCol, $SeriesCol)
    "graph.metrics"        = @($YCol)
    "stackable.stack_type" = "normalized"
  }
}

# Simple bar: x=col0, y=col1
function VizBar {
  param([string]$XCol, [string]$YCol)
  return @{
    "graph.dimensions" = @($XCol)
    "graph.metrics"    = @($YCol)
  }
}

# Line: x=col0, series=col1, y=col2
function VizLine {
  param([string]$XCol, [string]$SeriesCol, [string]$YCol)
  return @{
    "graph.dimensions" = @($XCol, $SeriesCol)
    "graph.metrics"    = @($YCol)
  }
}

# ------------------------------------------------------------------
# Card specs
# ------------------------------------------------------------------
$cards = @(

  # ================================================================
  # SECTION 0 -- Dashboard Header (narrative table, stays as table)
  # ================================================================
  @{
    Name       = "FVSD Literacy Intervention Planning -- Dashboard Guide"
    Description = "Introduction: what this dashboard covers, intervention tier logic, filter usage, and forecast caveat."
    Display    = "table"
    Row = 0; Col = 0; SizeX = 24; SizeY = 10
    FilterTags = @()
    VizSettings = @{}
    Query = @"
select 1 as sort_order,
  'About this dashboard' as topic,
  'FVSD uses three recurring literacy assessments -- TOSREC, TOWRE, TOSWRF -- across 21 schools in Northwest Alberta. This dashboard translates results into operational decisions: how many students need support, how many teachers are required, and what the cost implications are per term.' as detail
union all
select 2, 'Five sections',
  '1. Assessment Performance  2. Intervention Demand  3. Staffing and Cost Forecast  4. School Deep Dive  5. Insights and Key Findings'
union all
select 3, 'Intervention tiers',
  'Tier 3: score < 80 (1 teacher / 5 students).  Tier 2: score 80-89 (1 teacher / 10 students).  No Intervention: score >= 90.'
union all
select 4, 'How to filter',
  'Use the School Year, Semester, and School filters at the top to narrow any filterable card.'
union all
select 5, 'Forecast caveat',
  '2023 / 2024 data is partial (last assessment: 2023-11-30). Winter 2023 / 2024 cards are planning scenarios from Fall 2023 / 2024, not confirmed actuals.'
order by sort_order
"@
  },

  # ================================================================
  # SECTION 1 -- Assessment Performance
  # ================================================================
  @{
    Name        = "-- Section 1: Assessment Performance --"
    Description = "Student counts, proficiency mix, score trend, and level changes across terms."
    Display     = "table"
    Row = 10; Col = 0; SizeX = 24; SizeY = 3
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as n, 'What this section shows' as item, 'Student count by proficiency level and assessment type, share mix over time, score trends, and level changes vs previous term and prior year.' as detail
union all select 2, 'Key question', 'Is the proficiency mix improving, holding, or deteriorating?'
order by n
"@
  },

  @{
    Name        = "Student Count by Assessment Level"
    Description = "Stacked bar: how many students fall into each proficiency level per term."
    Display     = "bar"
    Row = 13; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizStackedBar -XCol "period" -SeriesCol "assessment_level" -YCol "student_count"
    Query = @"
select
  school_year || ' - ' || semester as period,
  assessment_level,
  sum(student_count) as student_count
from vw_fvsd_assessment_level_distribution
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by 1, 2
order by min(term_order), assessment_level
"@
  },

  @{
    Name        = "Student Count by Assessment Type"
    Description = "Line chart: testing volume per assessment type across all terms."
    Display     = "line"
    Row = 13; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizLine -XCol "period" -SeriesCol "assessment_type" -YCol "student_count"
    Query = @"
select
  school_year || ' - ' || semester as period,
  assessment_type,
  sum(student_count) as student_count
from vw_fvsd_assessment_type_distribution
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by 1, 2
order by min(term_order), assessment_type
"@
  },

  @{
    Name        = "Assessment Level Share %"
    Description = "100% stacked bar: proficiency mix share per term -- compares risk concentration regardless of enrollment size."
    Display     = "bar"
    Row = 23; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizNormalizedBar -XCol "period" -SeriesCol "assessment_level" -YCol "student_count"
    Query = @"
select
  school_year || ' - ' || semester as period,
  assessment_level,
  sum(student_count) as student_count
from vw_fvsd_assessment_level_distribution
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by 1, 2
order by min(term_order), assessment_level
"@
  },

  @{
    Name        = "Below Average vs Average and Above Share %"
    Description = "100% stacked bar: executive risk share -- Below Average vs Average and Above per term."
    Display     = "bar"
    Row = 23; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizNormalizedBar -XCol "period" -SeriesCol "level_grouping" -YCol "student_count"
    Query = @"
select
  school_year || ' - ' || semester as period,
  level_grouping,
  sum(student_count) as student_count
from vw_fvsd_assessment_level_group_distribution
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by 1, 2
order by min(term_order), level_grouping
"@
  },

  @{
    Name        = "Average Score Trend by Assessment Type"
    Description = "Line chart: are average standard scores improving or declining over time per assessment type?"
    Display     = "line"
    Row = 33; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @()
    VizSettings = VizLine -XCol "period" -SeriesCol "assessment_type" -YCol "avg_standard_score"
    Query = @"
select
  period,
  assessment_type,
  avg_standard_score
from vw_fvsd_average_score_trend
order by school_year, term_order, assessment_type
"@
  },

  @{
    Name        = "Assessment Level Change vs Previous Term"
    Description = "Bar chart: absolute change in student count per proficiency level vs the prior term. Positive = more students in that level."
    Display     = "bar"
    Row = 33; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @()
    VizSettings = VizStackedBar -XCol "period" -SeriesCol "assessment_level" -YCol "change_vs_previous_term"
    Query = @"
select
  school_year || ' - ' || semester as period,
  assessment_level,
  change_vs_previous_term
from vw_fvsd_assessment_level_change
where change_vs_previous_term is not null
order by school_year, term_order, assessment_level
"@
  },

  # ================================================================
  # SECTION 2 -- Intervention Demand
  # ================================================================
  @{
    Name        = "-- Section 2: Intervention Demand --"
    Description = "Tier breakdown, school pressure, grade risk, and term-over-term changes."
    Display     = "table"
    Row = 43; Col = 0; SizeX = 24; SizeY = 3
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as n, 'What this section shows' as item, 'Tier 2 vs Tier 3 student counts, school pressure ranking, grade-level risk by assessment type, and how intervention demand changed vs last term and last year.' as detail
union all select 2, 'Key question', 'Which schools and grades carry the highest burden, and is it growing or easing?'
order by n
"@
  },

  @{
    Name        = "Tier 2 vs Tier 3 Demand by School"
    Description = "Stacked bar: moderate (Tier 2) vs intensive (Tier 3) student demand per school. Sorted by total required teachers."
    Display     = "bar"
    Row = 46; Col = 0; SizeX = 12; SizeY = 12
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizStackedBar -XCol "school_name" -SeriesCol "tier" -YCol "students"
    Query = @"
select
  school_name,
  'Tier 2' as tier,
  sum(tier_2_students) as students
from fact_intervention_demand
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by school_name
union all
select
  school_name,
  'Tier 3',
  sum(tier_3_students)
from fact_intervention_demand
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by school_name
order by school_name
"@
  },

  @{
    Name        = "School Pressure Ranking"
    Description = "Bar chart: schools ranked by total required intervention teachers across all observed terms."
    Display     = "bar"
    Row = 46; Col = 12; SizeX = 12; SizeY = 12
    FilterTags  = @()
    VizSettings = VizBar -XCol "school_name" -YCol "total_required_teachers"
    Query = @"
select
  school_name,
  sum(total_required_teachers) as total_required_teachers
from vw_fvsd_school_pressure
group by school_name
order by total_required_teachers desc
limit 20
"@
  },

  @{
    Name        = "Grade Risk by Assessment Type"
    Description = "Line chart: intervention rate per grade for each assessment type -- shows which grades carry the most persistent literacy risk."
    Display     = "line"
    Row = 58; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester")
    VizSettings = VizLine -XCol "grade_number" -SeriesCol "assessment_type" -YCol "intervention_rate"
    Query = @"
select
  grade_number,
  assessment_type,
  round(avg(intervention_rate), 4) as intervention_rate
from vw_fvsd_grade_assessment_mix
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
group by grade_number, assessment_type
order by grade_number, assessment_type
"@
  },

  @{
    Name        = "Change vs Previous Term -- Intervention Students by School"
    Description = "Bar chart: how intervention student counts changed vs the immediately prior term per school. Positive = more students needing support."
    Display     = "bar"
    Row = 58; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizBar -XCol "school_name" -YCol "delta_intervention_students"
    Query = @"
select
  school_name,
  sum(delta_intervention_students) as delta_intervention_students
from vw_fvsd_term_comparison
where delta_intervention_students is not null
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by school_name
order by delta_intervention_students desc
"@
  },

  @{
    Name        = "YoY Same-Term Change -- Intervention Students by School"
    Description = "Bar chart: year-over-year change in intervention students for the same semester. Shows structural trend vs seasonal variation."
    Display     = "bar"
    Row = 68; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = VizBar -XCol "school_name" -YCol "yoy_delta_intervention"
    Query = @"
select
  school_name,
  sum(yoy_delta_intervention) as yoy_delta_intervention
from vw_fvsd_yoy_same_term
where prior_year_intervention_students is not null
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
group by school_name
order by yoy_delta_intervention desc
"@
  },

  @{
    Name        = "YoY Average Score Change by Assessment Type"
    Description = "Bar chart: year-over-year change in average standard score per assessment type and school."
    Display     = "bar"
    Row = 68; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @("school_year", "semester")
    VizSettings = VizStackedBar -XCol "school_name" -SeriesCol "assessment_type" -YCol "yoy_pct_score_change"
    Query = @"
select
  school_name,
  assessment_type,
  round(avg(yoy_pct_score_change), 4) as yoy_pct_score_change
from vw_fvsd_yoy_same_term
where prior_year_intervention_students is not null
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
group by school_name, assessment_type
order by school_name, assessment_type
"@
  },

  # ================================================================
  # SECTION 3 -- Staffing and Cost Forecast
  # ================================================================
  @{
    Name        = "-- Section 3: Staffing and Cost Forecast --"
    Description = "Winter 2023 / 2024 staffing projections, testing cost structure, and next-term planning numbers."
    Display     = "table"
    Row = 78; Col = 0; SizeX = 24; SizeY = 3
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as n, 'What this section shows' as item, 'Direct answer to the planning question: how many Tier 2 / Tier 3 teachers are needed for Winter 2023 / 2024, what will testing cost, and where are the largest cost drivers.' as detail
union all select 2, 'Key question', 'What staffing and budget commitments does FVSD need for Winter 2023 / 2024?'
order by n
"@
  },

  @{
    Name        = "Winter 2023 / 2024 Forecast -- Teachers Required by School"
    Description = "Stacked bar: Tier 2 and Tier 3 teacher demand per school for Winter 2023 / 2024, based on Fall 2023 / 2024 actuals."
    Display     = "bar"
    Row = 81; Col = 0; SizeX = 12; SizeY = 12
    FilterTags  = @("school_name")
    VizSettings = VizStackedBar -XCol "school_name" -SeriesCol "tier" -YCol "teachers"
    Query = @"
select school_name, 'Tier 2' as tier, sum(forecast_tier_2_teachers) as teachers
from vw_fvsd_winter_2023_2024_forecast
  [[where school_name = {{school_name}}]]
group by school_name
union all
select school_name, 'Tier 3', sum(forecast_tier_3_teachers)
from vw_fvsd_winter_2023_2024_forecast
  [[where school_name = {{school_name}}]]
group by school_name
order by school_name
"@
  },

  @{
    Name        = "Winter 2023 / 2024 Forecast -- Testing Cost by School"
    Description = "Bar chart: forecast testing cost per school for Winter 2023 / 2024, based on Fall 2023 / 2024 baseline."
    Display     = "bar"
    Row = 81; Col = 12; SizeX = 12; SizeY = 12
    FilterTags  = @("school_name")
    VizSettings = VizBar -XCol "school_name" -YCol "forecast_testing_cost"
    Query = @"
select
  school_name,
  sum(forecast_assessment_cost) as forecast_testing_cost
from vw_fvsd_winter_2023_2024_forecast
  [[where school_name = {{school_name}}]]
group by school_name
order by forecast_testing_cost desc
"@
  },

  @{
    Name        = "Executive Trend -- Intervention Rate by Assessment Type"
    Description = "Line chart: intervention rate over time per assessment type -- shows when risk rises or falls across terms."
    Display     = "line"
    Row = 93; Col = 0; SizeX = 12; SizeY = 10
    FilterTags  = @()
    VizSettings = VizLine -XCol "period" -SeriesCol "assessment_type" -YCol "intervention_rate"
    Query = @"
select
  school_year || ' - ' || semester as period,
  assessment_type,
  intervention_rate
from vw_fvsd_executive_overview
order by school_year,
  case semester when 'Fall' then 1 when 'Winter' then 2 when 'Spring' then 3 end,
  assessment_type
"@
  },

  @{
    Name        = "Assessment Program Cost by Test Type"
    Description = "Bar chart: total testing cost by assessment type across all terms."
    Display     = "bar"
    Row = 93; Col = 12; SizeX = 12; SizeY = 10
    FilterTags  = @()
    VizSettings = VizBar -XCol "assessment_type" -YCol "total_assessment_cost"
    Query = @"
select
  assessment_type,
  sum(total_assessment_cost) as total_assessment_cost
from fact_intervention_demand
group by assessment_type
order by total_assessment_cost desc
"@
  },

  @{
    Name        = "Next-Term Staffing Forecast -- Teachers Required by School"
    Description = "Bar chart: projected total intervention teacher demand per school for the upcoming term."
    Display     = "bar"
    Row = 103; Col = 0; SizeX = 24; SizeY = 10
    FilterTags  = @("school_name")
    VizSettings = VizBar -XCol "school_name" -YCol "forecast_total_teachers"
    Query = @"
select
  school_name,
  next_school_year,
  next_semester,
  sum(forecast_total_teachers) as forecast_total_teachers
from vw_fvsd_next_term_forecast
  [[where school_name = {{school_name}}]]
group by school_name, next_school_year, next_semester
order by forecast_total_teachers desc
"@
  },

  # ================================================================
  # SECTION 4 -- School Deep Dive (detail table -- intentionally kept)
  # ================================================================
  @{
    Name        = "-- Section 4: School Deep Dive --"
    Description = "School-level term metrics. Use the School filter above to focus on a single school."
    Display     = "table"
    Row = 113; Col = 0; SizeX = 24; SizeY = 3
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as n, 'What this section shows' as item, 'Full term-by-term metrics per school: students tested, intervention demand, teacher load, cost, and average score. Use the School filter to drill into one school.' as detail
union all select 2, 'Key question', 'For a specific school, how has intervention demand evolved over time?'
order by n
"@
  },

  @{
    Name        = "School-Level Term Metrics"
    Description = "Detail table: term-by-term intervention demand, teacher load, cost, and average score per school. Filterable by school, year, and semester."
    Display     = "table"
    Row = 116; Col = 0; SizeX = 24; SizeY = 12
    FilterTags  = @("school_year", "semester", "school_name")
    VizSettings = @{}
    Query = @"
select
  school_year,
  semester,
  school_name,
  municipality,
  assessment_type,
  assessment_group,
  total_students_tested,
  students_requiring_intervention,
  tier_2_students,
  tier_3_students,
  intervention_rate,
  avg_standard_score,
  total_required_teachers,
  total_assessment_cost
from vw_fvsd_term_metrics
where 1 = 1
  [[and school_year = {{school_year}}]]
  [[and semester    = {{semester}}]]
  [[and school_name = {{school_name}}]]
order by school_year desc, academic_period_index desc, school_name, assessment_type
"@
  },

  # ================================================================
  # SECTION 5 -- Insights and Key Findings (narrative table)
  # ================================================================
  @{
    Name        = "-- Section 5: Insights and Key Findings --"
    Description = "Synthesized takeaways for school planning decisions."
    Display     = "table"
    Row = 128; Col = 0; SizeX = 24; SizeY = 3
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as n, 'What this section shows' as item, 'Five evidence-based findings from the assessment data, each linked to a planning implication for FVSD leaders.' as detail
order by n
"@
  },

  @{
    Name        = "Key Findings"
    Description = "Five findings from the literacy data with themes, evidence, data sources, and planning implications."
    Display     = "table"
    Row = 131; Col = 0; SizeX = 24; SizeY = 14
    FilterTags  = @()
    VizSettings = @{}
    Query = @"
select 1 as finding_number,
  'Intervention demand is persistently high' as theme,
  'Across all terms, more than 40% of students assessed fall into Tier 2 or Tier 3 in most school-year slices.' as finding,
  'vw_fvsd_executive_overview, fact_intervention_demand' as data_source,
  'Treat Tier 2 and Tier 3 staffing as a baseline operational cost, not an emergency measure. Budget early.' as implication
union all
select 2,
  'Tier 3 demand is concentrated in specific schools',
  'A small set of schools accounts for a disproportionate share of total required teachers. Top-pressure schools are 3-5x the division average.',
  'vw_fvsd_school_pressure, vw_fvsd_term_metrics',
  'Direct additional staff, coaching, and PD to top-pressure schools first rather than spreading evenly.'
union all
select 3,
  'Average scores are stable but not improving',
  'TOSREC, TOWRE, and TOSWRF scores sit in a narrow band across 2021-2023. Interventions appear to contain decline but not drive recovery.',
  'vw_fvsd_average_score_trend, vw_fvsd_executive_overview',
  'Review whether Tier 2 students are graduating to No-Intervention status at expected rates. Consider program review.'
union all
select 4,
  'Winter 2023 / 2024 requires 634 combined intervention teachers',
  'Tier 2: 252 teachers (1 per 10 students). Tier 3: 382 teachers (1 per 5 students). Forecast testing cost ~$6,881.',
  'vw_fvsd_winter_2023_2024_forecast',
  'Verify staffing commitments before Winter 2023 / 2024 begins. If below 634, prioritize by school pressure ranking.'
union all
select 5,
  'Early-grade TOSREC risk is disproportionately high',
  'Grades 1-3 show the highest TOSREC intervention rates (>60% in Grade 1), while TOWRE and TOSWRF risk is more evenly distributed.',
  'vw_fvsd_grade_assessment_mix',
  'Early literacy investment in Grades 1-3 targeting decoding (TOSREC domain) is likely to yield the highest downstream impact.'
order by finding_number
"@
  }
)

# ------------------------------------------------------------------
# Create all cards and build dashcard list
# ------------------------------------------------------------------
$dashcards = @()
$tempId = -1

foreach ($cardSpec in $cards) {
  $tags = @{}
  foreach ($tagName in $cardSpec.FilterTags) {
    $tags[$tagName] = $filterTags[$tagName]
  }

  $viz = $cardSpec.VizSettings
  if ($null -eq $viz) { $viz = @{} }

  $card = New-NativeCard `
    -Name        $cardSpec.Name `
    -Description $cardSpec.Description `
    -Display     $cardSpec.Display `
    -Query       $cardSpec.Query `
    -TemplateTags $tags `
    -VizSettings  $viz

  [array]$mappings = New-ParamMappings -CardId $card.id -Tags $cardSpec.FilterTags
  if ($null -eq $mappings) { [array]$mappings = @() }

  $dashcards += @{
    id                     = $tempId
    card_id                = $card.id
    row                    = $cardSpec.Row
    col                    = $cardSpec.Col
    size_x                 = $cardSpec.SizeX
    size_y                 = $cardSpec.SizeY
    parameter_mappings     = $mappings
    visualization_settings = New-Object PSObject
  }
  $tempId -= 1
}

# ------------------------------------------------------------------
# PUT dashboard with filters and dashcards
# ------------------------------------------------------------------
Invoke-Mb -Method Put -Path "/api/dashboard/$($dashboard.id)" -Body @{
  name          = $dashboard.name
  description   = $dashboard.description
  collection_id = $dashboard.collection_id
  tabs          = @()
  parameters    = @($paramSchoolYear, $paramSemester, $paramSchool)
  dashcards     = $dashcards
} -Headers $script:Auth | Out-Null

[pscustomobject]@{
  dashboard_id  = $dashboard.id
  dashboard_url = "$BaseUrl/dashboard/$($dashboard.id)"
  card_count    = $cards.Count
} | ConvertTo-Json -Depth 4
