from __future__ import annotations

import json
from math import ceil
from pathlib import Path

import pandas as pd


TERM_ORDER = {"Fall": 1, "Winter": 2, "Spring": 3}


def parse_grade(value: object) -> int | None:
    text = str(value).strip()
    if not text:
        return None
    digits = "".join(ch for ch in text if ch.isdigit())
    return int(digits) if digits else None


def next_term(school_year: str, semester: str) -> tuple[str, str]:
    if semester == "Fall":
        return school_year, "Winter"
    if semester == "Winter":
        return school_year, "Spring"
    start_year, end_year = [int(part.strip()) for part in school_year.split("/")]
    return f"{start_year + 1} / {end_year + 1}", "Fall"


def classify_tier(score: float) -> str:
    if pd.isna(score):
        return "Unknown"
    if score < 80:
        return "Tier 3"
    if score < 90:
        return "Tier 2"
    return "No Intervention"


def forecast_segment(group: pd.DataFrame) -> dict[str, object]:
    latest = group.sort_values(["school_year", "term_order"]).iloc[-1]
    overall_intervention = group["students_requiring_intervention"].mean()
    next_school_year, next_semester = next_term(latest["school_year"], latest["semester"])
    same_semester = group[group["semester"] == next_semester]
    seasonal_intervention = same_semester["students_requiring_intervention"].mean() if not same_semester.empty else overall_intervention
    seasonal_tested = same_semester["total_students_tested"].mean() if not same_semester.empty else group["total_students_tested"].mean()
    forecast_intervention = round((0.6 * latest["students_requiring_intervention"]) + (0.4 * seasonal_intervention))
    forecast_tested = max(round((0.6 * latest["total_students_tested"]) + (0.4 * seasonal_tested)), forecast_intervention)
    tier2_share = group["tier_2_students"].sum() / max(group["students_requiring_intervention"].sum(), 1)
    forecast_tier2 = round(forecast_intervention * tier2_share)
    forecast_tier3 = max(forecast_intervention - forecast_tier2, 0)
    return {
        "school_id": latest["school_id"],
        "school_name": latest["school_name"],
        "municipality": latest["municipality"],
        "assessment_type": latest["assessment_type"],
        "grade_number": latest["grade_number"],
        "next_school_year": next_school_year,
        "next_semester": next_semester,
        "baseline_school_year": latest["school_year"],
        "baseline_semester": latest["semester"],
        "forecast_students_tested": forecast_tested,
        "forecast_students_requiring_intervention": forecast_intervention,
        "forecast_tier_2_students": forecast_tier2,
        "forecast_tier_3_students": forecast_tier3,
        "forecast_tier_2_teachers": ceil(forecast_tier2 / 10) if forecast_tier2 else 0,
        "forecast_tier_3_teachers": ceil(forecast_tier3 / 5) if forecast_tier3 else 0,
        "forecast_total_teachers": (ceil(forecast_tier2 / 10) if forecast_tier2 else 0) + (ceil(forecast_tier3 / 5) if forecast_tier3 else 0),
        "assessment_cost_per_student": latest["assessment_cost_per_student"],
        "forecast_assessment_cost": round(forecast_tested * latest["assessment_cost_per_student"], 2),
        "forecast_method": "0.6 * latest segment + 0.4 * seasonal-or-overall history",
    }


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    source_path = project_root / "docs" / "Education_Management_Dataset.xlsx"
    exports_dir = project_root / "docs" / "assets" / "exports"
    exports_dir.mkdir(parents=True, exist_ok=True)

    school = pd.read_excel(source_path, sheet_name="School").rename(columns={"School ID": "school_id", "School Name": "school_name", "Municipality": "municipality"})
    students = pd.read_excel(source_path, sheet_name="Students").rename(columns={"Student ID": "student_id", "Date of Birth": "date_of_birth", "Gender": "gender", "Student Name": "student_name", "School ID": "school_id"})
    test_details = pd.read_excel(source_path, sheet_name="Test Details").rename(columns={"Assessment Group": "assessment_group", "Assessment Type": "assessment_type", "Description": "description", "Assesment Cost": "assessment_cost_per_student"})
    grading = pd.read_excel(source_path, sheet_name="Grading Groups").rename(columns={"Assessement Level ID": "assessment_level_id", "Assessement Level": "assessment_level", "Level Grouping": "level_grouping", "Score Range": "score_range"})
    tests = pd.read_excel(source_path, sheet_name="Tests").rename(
        columns={
            "Standard Score": "standard_score",
            "Assessement Level ID": "assessment_level_id",
            "Student Assessment ID": "student_assessment_id",
            "Student ID": "student_id",
            "Assessment Type": "assessment_type",
            "Assessment Date": "assessment_date",
            "School Year / Grade / Class": "school_year_grade_class",
            "Semester": "semester",
            "School Year2": "school_year",
            "TOSWRF Assessment ID": "toswrf_assessment_id",
            "TOWRE Assessment ID": "towre_assessment_id",
            "Grade at Assessment": "grade_label",
        }
    )

    join_students = tests.merge(students[["student_id", "school_id"]], on="student_id", how="left", indicator=True)
    join_levels = tests.merge(grading[["assessment_level_id"]], on="assessment_level_id", how="left", indicator=True)
    student_school_validation = students.merge(school[["school_id"]], on="school_id", how="left", indicator=True)

    dim_school = school.drop_duplicates().sort_values(["municipality", "school_name"])
    dim_student = (
        students.assign(date_of_birth=pd.to_datetime(students["date_of_birth"], errors="coerce"))
        .drop(columns=["student_name"])
        .drop_duplicates("student_id")
    )
    valid_school_ids = set(dim_school["school_id"].dropna().astype(str))
    dim_student["school_id"] = dim_student["school_id"].where(dim_student["school_id"].astype(str).isin(valid_school_ids))
    dim_assessment_type = test_details.drop_duplicates("assessment_type").sort_values("assessment_type")
    dim_assessment_level = grading.drop_duplicates("assessment_level_id").sort_values(["level_grouping", "assessment_level"])

    fact_student_assessment = (
        tests.merge(dim_student[["student_id", "school_id", "gender", "date_of_birth"]], on="student_id", how="left")
        .merge(dim_school, on="school_id", how="left")
        .merge(dim_assessment_type, on="assessment_type", how="left")
        .merge(dim_assessment_level, on="assessment_level_id", how="left")
    )
    fact_student_assessment["assessment_date"] = pd.to_datetime(fact_student_assessment["assessment_date"], errors="coerce")
    fact_student_assessment["grade_number"] = fact_student_assessment["grade_label"].map(parse_grade)
    fact_student_assessment["term_order"] = fact_student_assessment["semester"].map(TERM_ORDER)
    fact_student_assessment["intervention_tier"] = fact_student_assessment["standard_score"].map(classify_tier)
    fact_student_assessment["requires_intervention"] = fact_student_assessment["intervention_tier"].isin(["Tier 2", "Tier 3"])
    fact_student_assessment["assessment_cost"] = fact_student_assessment["assessment_cost_per_student"].fillna(0.0)
    fact_student_assessment["below_average_flag"] = fact_student_assessment["level_grouping"].eq("Below Average")

    fact_intervention_demand = (
        fact_student_assessment.groupby(["school_id", "school_name", "municipality", "school_year", "semester", "term_order", "assessment_type", "grade_number"], dropna=False)
        .agg(
            total_students_tested=("student_assessment_id", "count"),
            students_requiring_intervention=("requires_intervention", "sum"),
            tier_2_students=("intervention_tier", lambda s: (s == "Tier 2").sum()),
            tier_3_students=("intervention_tier", lambda s: (s == "Tier 3").sum()),
            below_average_students=("below_average_flag", "sum"),
            average_standard_score=("standard_score", "mean"),
            assessment_cost_per_student=("assessment_cost_per_student", "max"),
        )
        .reset_index()
    )
    fact_intervention_demand["tier_2_teachers"] = fact_intervention_demand["tier_2_students"].map(lambda x: ceil(x / 10) if x else 0)
    fact_intervention_demand["tier_3_teachers"] = fact_intervention_demand["tier_3_students"].map(lambda x: ceil(x / 5) if x else 0)
    fact_intervention_demand["total_required_teachers"] = fact_intervention_demand["tier_2_teachers"] + fact_intervention_demand["tier_3_teachers"]
    fact_intervention_demand["intervention_rate"] = (fact_intervention_demand["students_requiring_intervention"] / fact_intervention_demand["total_students_tested"]).round(4)
    fact_intervention_demand["total_assessment_cost"] = (fact_intervention_demand["total_students_tested"] * fact_intervention_demand["assessment_cost_per_student"]).round(2)

    forecast_rows = []
    for _, segment in fact_intervention_demand.groupby(["school_id", "assessment_type", "grade_number"], dropna=False):
        forecast_rows.append(forecast_segment(segment))
    forecast = pd.DataFrame(forecast_rows).sort_values(["school_name", "assessment_type", "grade_number"]).reset_index(drop=True)

    outputs = {
        "dim-school.csv": dim_school,
        "dim-student.csv": dim_student,
        "dim-assessment-type.csv": dim_assessment_type,
        "dim-assessment-level.csv": dim_assessment_level,
        "fact-student-assessment.csv": fact_student_assessment,
        "fact-intervention-demand.csv": fact_intervention_demand,
        "fact-forecast-intervention-demand.csv": forecast,
    }
    for filename, frame in outputs.items():
        frame.to_csv(exports_dir / filename, index=False)

    summary = {
        "source_file": str(source_path),
        "schools": int(len(dim_school)),
        "students": int(len(dim_student)),
        "assessments": int(len(fact_student_assessment)),
        "intervention_segments": int(len(fact_intervention_demand)),
        "forecast_segments": int(len(forecast)),
        "unmatched_student_ids_in_tests": int((join_students["_merge"] == "left_only").sum()),
        "unmatched_assessment_level_ids_in_tests": int((join_levels["_merge"] == "left_only").sum()),
        "duplicate_student_assessment_ids": int(fact_student_assessment["student_assessment_id"].duplicated().sum()),
        "students_with_orphan_school_ids": int((student_school_validation["_merge"] == "left_only").sum()),
        "missing_school_ids_after_join": int(fact_student_assessment["school_id"].isna().sum()),
        "missing_grade_numbers": int(fact_student_assessment["grade_number"].isna().sum()),
        "date_min": str(fact_student_assessment["assessment_date"].min().date()),
        "date_max": str(fact_student_assessment["assessment_date"].max().date()),
        "school_years": sorted(fact_student_assessment["school_year"].dropna().astype(str).unique().tolist()),
        "semesters": sorted(fact_student_assessment["semester"].dropna().astype(str).unique().tolist()),
        "assessment_types": sorted(fact_student_assessment["assessment_type"].dropna().astype(str).unique().tolist()),
    }
    (exports_dir / "data-preparation-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
