"""Project analysis entrypoint for the cooked FMCG marts."""

from pathlib import Path

EXPORTS_DIR = Path(__file__).resolve().parent


def describe_project():
    return {
        "project": "Grocery Supermarket Sales Performance Analytics Challenge",
        "primary_sql_engine": "SQL Server",
        "visualization_tool": "Power BI",
        "prepared_summary": str(EXPORTS_DIR / "data-preparation-summary.json"),
        "mart_files": sorted(path.name for path in EXPORTS_DIR.glob("mart-*.csv")),
        "next_step": "Open Power BI Desktop and import the cooked mart CSV files.",
    }


if __name__ == "__main__":
    print(describe_project())
