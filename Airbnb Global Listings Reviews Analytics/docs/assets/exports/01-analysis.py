"""Airbnb listings/reviews prep for Supabase + Metabase."""

from __future__ import annotations

import ast
import csv
import json
from collections import Counter, defaultdict
from datetime import date

from airbnb_analysis_config import (
    AMENITY_FLAGS,
    BINARY_FIELDS,
    CITY_CURRENCY,
    FX_LOCAL_PER_USD,
    LISTINGS,
    NUMERIC_FIELDS,
    OUTPUT_DIR,
    REVIEWS,
)
from airbnb_analysis_utils import bool_flag, clean_float, pearson, quantile, write_csv


def load_listings() -> dict:
    listing_city: dict[str, str] = {}
    city_prices: dict[str, list[float]] = defaultdict(list)
    city_ratings: dict[str, list[float]] = defaultdict(list)
    city_listing_counts = Counter()
    room_counts = Counter()
    correlations: dict[str, list[tuple[float, float]]] = defaultdict(list)
    amenity_counts = Counter()
    amenity_prices: dict[str, list[float]] = defaultdict(list)
    nulls = Counter()
    total = 0

    with LISTINGS.open(newline="", encoding="utf-8", errors="replace") as handle:
        for row in csv.DictReader(handle):
            total += 1
            city = row["city"]
            listing_city[row["listing_id"]] = city
            city_listing_counts[city] += 1
            room_counts[(city, row["room_type"])] += 1
            nulls.update(key for key, value in row.items() if value == "")
            price = clean_float(row["price"])
            currency = CITY_CURRENCY.get(city)
            rate = FX_LOCAL_PER_USD.get(currency or "")
            price_usd = price / rate if price is not None and rate else None
            if price_usd is None:
                continue
            city_prices[city].append(price_usd)
            rating = clean_float(row["review_scores_rating"])
            if rating is not None:
                city_ratings[city].append(rating)
            collect_correlations(row, price_usd, correlations)
            collect_amenities(row, price_usd, amenity_counts, amenity_prices)

    return {
        "total": total,
        "listing_city": listing_city,
        "city_prices": city_prices,
        "city_ratings": city_ratings,
        "city_listing_counts": city_listing_counts,
        "room_counts": room_counts,
        "correlations": correlations,
        "amenity_counts": amenity_counts,
        "amenity_prices": amenity_prices,
        "nulls": nulls,
    }


def collect_correlations(row: dict, price_usd: float, correlations: dict) -> None:
    for field in NUMERIC_FIELDS:
        value = clean_float(row.get(field))
        if value is not None:
            correlations[field].append((price_usd, value))
    for field in BINARY_FIELDS:
        value = bool_flag(row.get(field))
        if value is not None:
            correlations[field].append((price_usd, float(value)))


def collect_amenities(row: dict, price_usd: float, counts: Counter, prices: dict) -> None:
    try:
        amenities = ast.literal_eval(row["amenities"])
    except (SyntaxError, ValueError):
        amenities = []
    amenity_set = set(amenities)
    for amenity in AMENITY_FLAGS:
        if amenity in amenity_set:
            counts[amenity] += 1
            prices[amenity].append(price_usd)


def scan_reviews(listing_city: dict[str, str]) -> dict:
    monthly = Counter()
    city_review_counts = Counter()
    min_date = None
    max_date = None
    total = 0
    unmatched = 0
    with REVIEWS.open(newline="", encoding="utf-8", errors="replace") as handle:
        for row in csv.DictReader(handle):
            total += 1
            city = listing_city.get(row["listing_id"])
            if not city:
                unmatched += 1
                continue
            review_date = row["date"]
            monthly[(city, review_date[:7])] += 1
            city_review_counts[city] += 1
            min_date = review_date if min_date is None or review_date < min_date else min_date
            max_date = review_date if max_date is None or review_date > max_date else max_date
    return {
        "total": total,
        "unmatched": unmatched,
        "monthly": monthly,
        "city_review_counts": city_review_counts,
        "min_date": min_date,
        "max_date": max_date,
    }


def build_market_rows(listings: dict, reviews: dict, cities: list[str]) -> list[dict]:
    rows = []
    for city in cities:
        prices = listings["city_prices"][city]
        ratings = listings["city_ratings"][city]
        rows.append({
            "city": city,
            "currency": CITY_CURRENCY[city],
            "listing_count": listings["city_listing_counts"][city],
            "review_count": reviews["city_review_counts"][city],
            "median_price_usd": round(quantile(prices, 0.5) or 0, 2),
            "p25_price_usd": round(quantile(prices, 0.25) or 0, 2),
            "p75_price_usd": round(quantile(prices, 0.75) or 0, 2),
            "avg_rating": round(sum(ratings) / len(ratings), 2) if ratings else None,
        })
    return rows


def build_monthly_rows(reviews: dict) -> list[dict]:
    baseline_2019 = defaultdict(list)
    for (city, month), count in reviews["monthly"].items():
        if month.startswith("2019-"):
            baseline_2019[city].append(count)
    rows = []
    for (city, month), count in sorted(reviews["monthly"].items()):
        baseline = sum(baseline_2019[city]) / len(baseline_2019[city]) if baseline_2019[city] else None
        rows.append({
            "city": city,
            "review_month": month,
            "review_count": count,
            "baseline_2019_avg": round(baseline, 2) if baseline else None,
            "recovery_index": round(count / baseline, 3) if baseline else None,
        })
    return rows


def write_outputs(listings: dict, reviews: dict) -> None:
    cities = [city for city, _ in listings["city_listing_counts"].most_common()]
    market_rows = build_market_rows(listings, reviews, cities)
    write_csv(OUTPUT_DIR / "mart-city-market-landscape.csv", market_rows, list(market_rows[0]))
    room_rows = [{"city": c, "room_type": r, "listing_count": n} for (c, r), n in sorted(listings["room_counts"].items())]
    write_csv(OUTPUT_DIR / "mart-room-type-mix.csv", room_rows, ["city", "room_type", "listing_count"])
    monthly_rows = build_monthly_rows(reviews)
    write_csv(OUTPUT_DIR / "mart-monthly-tourism-pulse.csv", monthly_rows, list(monthly_rows[0]))
    write_drivers(listings)
    write_value_index(market_rows)
    write_fx_rates()
    write_summary(listings, reviews, cities)


def write_drivers(listings: dict) -> None:
    rows = []
    for field, pairs in listings["correlations"].items():
        corr = pearson(pairs)
        rows.append({"driver": field, "n": len(pairs), "pearson_with_price_usd": round(corr, 4) if corr is not None else None})
    rows.sort(key=lambda r: abs(r["pearson_with_price_usd"] or 0), reverse=True)
    write_csv(OUTPUT_DIR / "mart-price-driver-correlations.csv", rows, ["driver", "n", "pearson_with_price_usd"])
    all_prices = [p for values in listings["city_prices"].values() for p in values]
    global_avg = sum(all_prices) / len(all_prices)
    amenity_rows = []
    for amenity in AMENITY_FLAGS:
        values = listings["amenity_prices"][amenity]
        avg = sum(values) / len(values) if values else None
        amenity_rows.append({
            "amenity": amenity,
            "listing_count": listings["amenity_counts"][amenity],
            "avg_price_usd": round(avg, 2) if avg else None,
            "avg_price_premium_usd": round(avg - global_avg, 2) if avg else None,
        })
    write_csv(OUTPUT_DIR / "mart-amenity-price-premium.csv", amenity_rows, list(amenity_rows[0]))


def write_value_index(market_rows: list[dict]) -> None:
    medians = [row["median_price_usd"] for row in market_rows]
    min_price, max_price = min(medians), max(medians)
    rows = []
    for row in market_rows:
        affordability = 1 - ((row["median_price_usd"] - min_price) / (max_price - min_price))
        rating_norm = (row["avg_rating"] or 0) / 100
        rows.append({
            "city": row["city"],
            "median_price_usd": row["median_price_usd"],
            "avg_rating": row["avg_rating"],
            "affordability_score": round(affordability, 4),
            "rating_score": round(rating_norm, 4),
            "value_index": round((rating_norm * 0.6) + (affordability * 0.4), 4),
        })
    rows.sort(key=lambda r: r["value_index"], reverse=True)
    write_csv(OUTPUT_DIR / "mart-value-for-money-city.csv", rows, list(rows[0]))


def write_fx_rates() -> None:
    rows = [{"currency": c, "local_per_usd": r, "rate_year": 2020} for c, r in FX_LOCAL_PER_USD.items()]
    write_csv(OUTPUT_DIR / "fx-rates-2020.csv", rows, ["currency", "local_per_usd", "rate_year"])


def write_summary(listings: dict, reviews: dict, cities: list[str]) -> None:
    summary = {
        "generated_at": date.today().isoformat(),
        "listing_rows": listings["total"],
        "review_rows": reviews["total"],
        "unmatched_review_rows": reviews["unmatched"],
        "review_min_date": reviews["min_date"],
        "review_max_date": reviews["max_date"],
        "canonical_cities": cities,
        "null_counts_top_12": listings["nulls"].most_common(12),
        "exchange_rate_method": "fixed 2020 annual-average local currency per USD",
    }
    (OUTPUT_DIR / "data-quality-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


def main() -> None:
    listings = load_listings()
    reviews = scan_reviews(listings["listing_city"])
    write_outputs(listings, reviews)


if __name__ == "__main__":
    main()
