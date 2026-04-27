from __future__ import annotations

import json
from pathlib import Path

import pandas as pd


DAY_ORDER = {
    "Monday": 1,
    "Tuesday": 2,
    "Wednesday": 3,
    "Thursday": 4,
    "Friday": 5,
    "Saturday": 6,
    "Sunday": 7,
}

COUNTRY_TO_REGION = {
    "USA": "North America",
    "Canada": "North America",
    "Brazil": "Latin America",
    "UK": "Europe",
    "Germany": "Europe",
    "India": "APAC",
    "Japan": "APAC",
    "Australia": "APAC",
}

PLATFORM_LABELS = {
    "X.com": "X (Twitter)",
    "X": "X (Twitter)",
    "Twitter": "X (Twitter)",
}

CHALLENGE_PLATFORMS = {"TikTok", "Instagram", "LinkedIn", "X (Twitter)"}
CHALLENGE_START = pd.Timestamp("2024-06-01")
CHALLENGE_END = pd.Timestamp("2024-06-30")

PROMOTION_LABELS = {
    "Organic": "Organic",
    "Sponsored": "Paid/Promoted",
}


def hour_bucket(hour: float | int | None) -> str:
    if pd.isna(hour):
        return "Unknown"
    hour = int(hour)
    if hour < 10:
        return "08:00-09:59"
    if hour < 12:
        return "10:00-11:59"
    if hour < 14:
        return "12:00-13:59"
    if hour < 16:
        return "14:00-15:59"
    if hour < 18:
        return "16:00-17:59"
    return "18:00-19:59"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    source_path = project_root / "docs" / "assets" / "user-files" / "social-media-content-performance-dataset.xlsx"
    exports_dir = project_root / "docs" / "assets" / "exports"
    exports_dir.mkdir(parents=True, exist_ok=True)

    frame = pd.read_excel(source_path).rename(
        columns={
            "Post_ID": "post_id",
            "Platform": "platform",
            "Content_Type": "content_type",
            "Content_Category": "content_category",
            "Post_Type": "post_type",
            "Country": "country",
            "Region": "region",
            "Longitude": "longitude",
            "Latitude": "latitude",
            "Engagement": "engagement",
            "Views": "views",
            "Likes": "likes",
            "Shares": "shares",
            "Comments": "comments",
            "Engagement_Rate": "engagement_rate",
            "Impressions": "impressions",
            "Video_Views": "video_views",
            "Live_Stream_Views": "live_stream_views",
            "Clicks": "clicks",
            "Click_Through_Rate": "click_through_rate",
            "Main_Hashtag": "main_hashtag",
            "Post_Published_At": "post_published_at",
            "Post_Date": "post_date",
            "Post_Hour": "post_hour",
            "Engagement_Level": "engagement_level",
        }
    )
    frame.insert(0, "source_row_number", range(1, len(frame) + 1))
    frame.insert(1, "post_row_id", [f"post_row_{idx}" for idx in range(1, len(frame) + 1)])

    frame["source_platform"] = frame["platform"].astype("string")
    frame["platform"] = frame["source_platform"].replace(PLATFORM_LABELS)
    frame["source_region"] = frame["region"].astype("string")
    if "country" not in frame.columns:
        frame["country"] = frame["source_region"]
    frame["country"] = frame["country"].astype("string").str.strip()
    frame["region"] = frame["country"].map(COUNTRY_TO_REGION).fillna("Other")
    frame["promotion_type"] = frame["content_type"].map(PROMOTION_LABELS).fillna(frame["content_type"])

    numeric_cols = [
        "longitude",
        "latitude",
        "engagement",
        "views",
        "likes",
        "shares",
        "comments",
        "engagement_rate",
        "impressions",
        "video_views",
        "live_stream_views",
        "clicks",
        "click_through_rate",
        "post_hour",
    ]
    for column in numeric_cols:
        frame[column] = pd.to_numeric(frame[column], errors="coerce")

    frame["post_published_at"] = pd.to_datetime(frame["post_published_at"], errors="coerce")
    frame["post_date"] = pd.to_datetime(frame["post_date"], errors="coerce")
    frame["published_day_of_week"] = frame["post_date"].dt.day_name()
    frame["published_day_sort"] = frame["published_day_of_week"].map(DAY_ORDER)
    frame["published_month"] = frame["post_date"].dt.to_period("M").astype(str)
    frame["published_hour_bucket"] = frame["post_hour"].map(hour_bucket)
    frame["clicks_available"] = frame["clicks"].notna()
    frame["ctr_available"] = frame["click_through_rate"].notna()
    frame["is_click_trackable"] = frame["clicks_available"] | frame["ctr_available"]
    frame["is_video_post"] = frame["video_views"].fillna(0).gt(0) | frame["post_type"].eq("Video")
    frame["is_live_stream_post"] = frame["live_stream_views"].fillna(0).gt(0) | frame["post_type"].eq("Live Stream")
    frame["is_challenge_scope"] = frame["post_date"].between(CHALLENGE_START, CHALLENGE_END) & frame["platform"].isin(CHALLENGE_PLATFORMS)
    frame["scope_segment"] = frame["is_challenge_scope"].map({True: "Challenge Scope", False: "Full Workbook Only"})
    frame["reach_efficiency"] = (frame["engagement"] / frame["impressions"]).where(frame["impressions"].gt(0))
    frame["click_efficiency"] = (frame["clicks"] / frame["impressions"]).where(frame["impressions"].gt(0))
    frame["view_efficiency"] = (frame["views"] / frame["impressions"]).where(frame["impressions"].gt(0))
    frame["video_view_share"] = (frame["video_views"] / frame["views"]).where(frame["views"].gt(0))
    frame["live_stream_view_share"] = (frame["live_stream_views"] / frame["views"]).where(frame["views"].gt(0))
    frame["content_key"] = (
        frame["content_type"].astype(str)
        + " | "
        + frame["promotion_type"].astype(str)
        + " | "
        + frame["content_category"].astype(str)
        + " | "
        + frame["post_type"].astype(str)
    )

    dim_platform = pd.DataFrame({"platform": sorted(frame["platform"].dropna().astype(str).unique())})
    dim_platform["channel_group"] = dim_platform["platform"]
    dim_platform["is_challenge_platform"] = dim_platform["platform"].isin(CHALLENGE_PLATFORMS)
    dim_region = (
        frame.groupby(["region", "country"], dropna=False)
        .agg(longitude=("longitude", "median"), latitude=("latitude", "median"))
        .reset_index()
        .sort_values(["region", "country"])
    )
    dim_content = (
        frame[["content_key", "content_type", "promotion_type", "content_category", "post_type"]]
        .drop_duplicates()
        .sort_values(["promotion_type", "content_category", "post_type"])
    )
    dim_hashtag = (
        frame[["main_hashtag"]]
        .drop_duplicates()
        .sort_values("main_hashtag")
        .reset_index(drop=True)
    )

    fact_post = frame[
        [
            "post_row_id",
            "source_row_number",
            "post_id",
            "source_platform",
            "platform",
            "country",
            "region",
            "content_key",
            "main_hashtag",
            "post_published_at",
            "post_date",
            "published_day_of_week",
            "published_day_sort",
            "published_month",
            "post_hour",
            "published_hour_bucket",
            "engagement_level",
            "content_type",
            "promotion_type",
            "content_category",
            "post_type",
            "engagement",
            "views",
            "likes",
            "shares",
            "comments",
            "engagement_rate",
            "impressions",
            "video_views",
            "live_stream_views",
            "clicks",
            "click_through_rate",
            "reach_efficiency",
            "click_efficiency",
            "view_efficiency",
            "video_view_share",
            "live_stream_view_share",
            "is_click_trackable",
            "is_video_post",
            "is_live_stream_post",
            "is_challenge_scope",
            "scope_segment",
            "longitude",
            "latitude",
        ]
    ].copy()

    mart_platform = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "platform", "post_type", "content_type", "promotion_type"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            total_engagement=("engagement", "sum"),
            total_views=("views", "sum"),
            total_impressions=("impressions", "sum"),
            total_clicks=("clicks", "sum"),
            avg_engagement_rate=("engagement_rate", "mean"),
            avg_ctr=("click_through_rate", "mean"),
        )
        .reset_index()
    )
    mart_region_content = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "region", "country", "content_category", "platform"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            total_engagement=("engagement", "sum"),
            total_impressions=("impressions", "sum"),
            total_clicks=("clicks", "sum"),
            avg_engagement_rate=("engagement_rate", "mean"),
            avg_ctr=("click_through_rate", "mean"),
        )
        .reset_index()
    )
    mart_posting_time = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "platform", "published_day_of_week", "published_day_sort", "post_hour"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            avg_engagement=("engagement", "mean"),
            avg_views=("views", "mean"),
            avg_engagement_rate=("engagement_rate", "mean"),
            avg_ctr=("click_through_rate", "mean"),
        )
        .reset_index()
    )
    mart_hashtag = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "main_hashtag", "platform", "region", "country"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            total_impressions=("impressions", "sum"),
            total_clicks=("clicks", "sum"),
            avg_ctr=("click_through_rate", "mean"),
            avg_engagement_rate=("engagement_rate", "mean"),
        )
        .reset_index()
    )
    mart_content_type = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "promotion_type", "content_type", "platform"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            total_impressions=("impressions", "sum"),
            total_views=("views", "sum"),
            total_clicks=("clicks", "sum"),
            avg_engagement_rate=("engagement_rate", "mean"),
            avg_ctr=("click_through_rate", "mean"),
        )
        .reset_index()
    )
    mart_video_live = (
        fact_post.groupby(["scope_segment", "is_challenge_scope", "region", "country", "platform"], dropna=False)
        .agg(
            posts=("post_row_id", "count"),
            total_video_views=("video_views", "sum"),
            total_live_stream_views=("live_stream_views", "sum"),
            avg_video_views=("video_views", "mean"),
            avg_live_stream_views=("live_stream_views", "mean"),
        )
        .reset_index()
    )
    mart_correlation_inputs = fact_post[
        [
            "post_row_id",
            "scope_segment",
            "is_challenge_scope",
            "platform",
            "region",
            "country",
            "promotion_type",
            "content_category",
            "post_type",
            "published_day_of_week",
            "post_hour",
            "engagement",
            "views",
            "impressions",
            "clicks",
            "click_through_rate",
            "engagement_rate",
            "reach_efficiency",
            "click_efficiency",
            "view_efficiency",
            "video_views",
            "live_stream_views",
        ]
    ].copy()

    outputs = {
        "dim-platform.csv": dim_platform,
        "dim-region.csv": dim_region,
        "dim-content.csv": dim_content,
        "dim-hashtag.csv": dim_hashtag,
        "fact-social-post-performance.csv": fact_post,
        "mart-platform-performance.csv": mart_platform,
        "mart-region-content-performance.csv": mart_region_content,
        "mart-posting-time-performance.csv": mart_posting_time,
        "mart-hashtag-performance.csv": mart_hashtag,
        "mart-content-type-comparison.csv": mart_content_type,
        "mart-video-live-region-performance.csv": mart_video_live,
        "mart-correlation-inputs.csv": mart_correlation_inputs,
    }
    for filename, data in outputs.items():
        data.to_csv(exports_dir / filename, index=False)

    summary = {
        "source_file": str(source_path),
        "rows": int(len(frame)),
        "duplicate_post_ids": int(frame["post_id"].duplicated().sum()),
        "source_platforms": sorted(frame["source_platform"].dropna().astype(str).unique().tolist()),
        "platforms": sorted(frame["platform"].dropna().astype(str).unique().tolist()),
        "countries": sorted(frame["country"].dropna().astype(str).unique().tolist()),
        "source_regions": sorted(frame["source_region"].dropna().astype(str).unique().tolist()),
        "regions": sorted(frame["region"].dropna().astype(str).unique().tolist()),
        "content_types": sorted(frame["content_type"].dropna().astype(str).unique().tolist()),
        "promotion_types": sorted(frame["promotion_type"].dropna().astype(str).unique().tolist()),
        "content_categories": sorted(frame["content_category"].dropna().astype(str).unique().tolist()),
        "post_types": sorted(frame["post_type"].dropna().astype(str).unique().tolist()),
        "hashtags": int(frame["main_hashtag"].dropna().nunique()),
        "date_min": str(frame["post_date"].min().date()),
        "date_max": str(frame["post_date"].max().date()),
        "challenge_scope_rows": int(frame["is_challenge_scope"].sum()),
        "full_workbook_only_rows": int((~frame["is_challenge_scope"]).sum()),
        "country_source": "Country column" if "Country" in pd.read_excel(source_path, nrows=0).columns else "Derived from Region column",
        "missing_clicks": int(frame["clicks"].isna().sum()),
        "missing_ctr": int(frame["click_through_rate"].isna().sum()),
        "click_trackable_rows": int(frame["is_click_trackable"].sum()),
        "nonzero_video_rows": int(frame["video_views"].fillna(0).gt(0).sum()),
        "nonzero_live_stream_rows": int(frame["live_stream_views"].fillna(0).gt(0).sum()),
        "engagement_component_mismatch_rows": int(
            ((frame["engagement"].fillna(0) - (frame["likes"].fillna(0) + frame["shares"].fillna(0) + frame["comments"].fillna(0))).abs() >= 1e-9).sum()
        ),
    }
    (exports_dir / "data-preparation-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
