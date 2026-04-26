"""Extra marts required by the project-plan Metabase blueprint."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict

from airbnb_analysis_config import CITY_CURRENCY, FX_LOCAL_PER_USD, LISTINGS, OUTPUT_DIR
from airbnb_analysis_utils import bool_flag, clean_float, quantile, write_csv


def read_listings() -> dict:
    city_room_prices = defaultdict(list)
    city_room_ratings = defaultdict(list)
    city_room_counts = Counter()
    city_room_superhost_prices = defaultdict(list)
    city_room_regular_prices = defaultdict(list)
    neighbourhood_prices = defaultdict(list)
    neighbourhood_ratings = defaultdict(list)
    map_density = Counter()

    with LISTINGS.open(newline="", encoding="utf-8", errors="replace") as handle:
        for row in csv.DictReader(handle):
            city = row["city"]
            price = clean_float(row["price"])
            rate = FX_LOCAL_PER_USD[CITY_CURRENCY[city]]
            price_usd = price / rate if price is not None else None
            rating = clean_float(row["review_scores_rating"])
            room_key = (city, row["room_type"])
            if price_usd is not None:
                city_room_prices[room_key].append(price_usd)
                city_room_counts[room_key] += 1
                if bool_flag(row["host_is_superhost"]) == 1:
                    city_room_superhost_prices[room_key].append(price_usd)
                elif bool_flag(row["host_is_superhost"]) == 0:
                    city_room_regular_prices[room_key].append(price_usd)
                n_key = (city, row["neighbourhood"] or "Unknown")
                neighbourhood_prices[n_key].append(price_usd)
                if rating is not None:
                    neighbourhood_ratings[n_key].append(rating)
            if rating is not None:
                city_room_ratings[room_key].append(rating)
            lat = clean_float(row["latitude"])
            lon = clean_float(row["longitude"])
            if lat is not None and lon is not None:
                map_density[(city, round(lat, 2), round(lon, 2))] += 1

    return {
        "city_room_prices": city_room_prices,
        "city_room_ratings": city_room_ratings,
        "city_room_counts": city_room_counts,
        "city_room_superhost_prices": city_room_superhost_prices,
        "city_room_regular_prices": city_room_regular_prices,
        "neighbourhood_prices": neighbourhood_prices,
        "neighbourhood_ratings": neighbourhood_ratings,
        "map_density": map_density,
    }


def write_price_distribution(data: dict) -> None:
    rows = []
    for (city, room_type), values in sorted(data["city_room_prices"].items()):
        rows.append({
            "city": city,
            "room_type": room_type,
            "listing_count": data["city_room_counts"][(city, room_type)],
            "p25_price_usd": round(quantile(values, 0.25) or 0, 2),
            "median_price_usd": round(quantile(values, 0.5) or 0, 2),
            "p75_price_usd": round(quantile(values, 0.75) or 0, 2),
        })
    write_csv(OUTPUT_DIR / "mart-price-distribution-city-room.csv", rows, list(rows[0]))


def write_superhost_premium(data: dict) -> None:
    rows = []
    for key in sorted(data["city_room_prices"]):
        super_prices = data["city_room_superhost_prices"][key]
        regular_prices = data["city_room_regular_prices"][key]
        super_median = quantile(super_prices, 0.5)
        regular_median = quantile(regular_prices, 0.5)
        rows.append({
            "city": key[0],
            "room_type": key[1],
            "superhost_listing_count": len(super_prices),
            "regular_listing_count": len(regular_prices),
            "superhost_median_usd": round(super_median, 2) if super_median is not None else None,
            "regular_median_usd": round(regular_median, 2) if regular_median is not None else None,
            "premium_usd": round(super_median - regular_median, 2) if super_median is not None and regular_median is not None else None,
        })
    write_csv(OUTPUT_DIR / "mart-superhost-premium.csv", rows, list(rows[0]))


def write_map_density(data: dict) -> None:
    rows = [
        {"city": city, "latitude": lat, "longitude": lon, "listing_count": count}
        for (city, lat, lon), count in data["map_density"].items()
        if count >= 2
    ]
    rows.sort(key=lambda row: (row["city"], -row["listing_count"]))
    write_csv(OUTPUT_DIR / "mart-listing-density-map.csv", rows, list(rows[0]))


def write_value_segments(data: dict) -> None:
    rows = []
    medians = {key: quantile(values, 0.5) or 0 for key, values in data["city_room_prices"].items()}
    min_price = min(medians.values())
    max_price = max(medians.values())
    for key, median_price in medians.items():
        ratings = data["city_room_ratings"][key]
        if not ratings:
            continue
        rating_score = (sum(ratings) / len(ratings)) / 100
        affordability = 1 - ((median_price - min_price) / (max_price - min_price))
        rows.append({
            "city": key[0],
            "room_type": key[1],
            "listing_count": data["city_room_counts"][key],
            "median_price_usd": round(median_price, 2),
            "avg_rating": round(rating_score * 100, 2),
            "value_index": round((rating_score * 0.6) + (affordability * 0.4), 4),
        })
    rows.sort(key=lambda row: row["value_index"], reverse=True)
    write_csv(OUTPUT_DIR / "mart-city-room-value-segments.csv", rows, list(rows[0]))


def write_neighbourhood_drilldown(data: dict) -> None:
    rows = []
    for key, prices in data["neighbourhood_prices"].items():
        ratings = data["neighbourhood_ratings"][key]
        if len(prices) < 30 or not ratings:
            continue
        rows.append({
            "city": key[0],
            "neighbourhood": key[1],
            "listing_count": len(prices),
            "median_price_usd": round(quantile(prices, 0.5) or 0, 2),
            "avg_rating": round(sum(ratings) / len(ratings), 2),
        })
    rows.sort(key=lambda row: (-row["avg_rating"], row["median_price_usd"]))
    write_csv(OUTPUT_DIR / "mart-neighbourhood-value-drilldown.csv", rows[:500], list(rows[0]))


def write_monthly_derivatives() -> None:
    monthly_path = OUTPUT_DIR / "mart-monthly-tourism-pulse.csv"
    by_city_month = defaultdict(list)
    rows = list(csv.DictReader(monthly_path.open(newline="", encoding="utf-8")))
    for row in rows:
        by_city_month[(row["city"], row["review_month"][5:7])].append(int(row["review_count"]))
    seasonality = []
    for (city, month_number), counts in sorted(by_city_month.items()):
        seasonality.append({"city": city, "month_number": month_number, "avg_review_count": round(sum(counts) / len(counts), 2)})
    write_csv(OUTPUT_DIR / "mart-seasonality-heatmap.csv", seasonality, list(seasonality[0]))

    callouts = []
    by_city = defaultdict(list)
    for row in rows:
        by_city[row["city"]].append(row)
    for city, city_rows in by_city.items():
        peak = max(city_rows, key=lambda row: int(row["review_count"]))
        trough = min((row for row in city_rows if row["review_month"] >= "2020-04"), key=lambda row: int(row["review_count"]))
        latest = max(city_rows, key=lambda row: row["review_month"])
        callouts.extend([
            {"city": city, "callout_type": "Peak month", "review_month": peak["review_month"], "review_count": peak["review_count"], "recovery_index": peak["recovery_index"]},
            {"city": city, "callout_type": "COVID stagnation low", "review_month": trough["review_month"], "review_count": trough["review_count"], "recovery_index": trough["recovery_index"]},
            {"city": city, "callout_type": "Latest month", "review_month": latest["review_month"], "review_count": latest["review_count"], "recovery_index": latest["recovery_index"]},
        ])
    write_csv(OUTPUT_DIR / "mart-tourism-peak-stagnation-callouts.csv", callouts, list(callouts[0]))


def main() -> None:
    data = read_listings()
    write_price_distribution(data)
    write_superhost_premium(data)
    write_map_density(data)
    write_value_segments(data)
    write_neighbourhood_drilldown(data)
    write_monthly_derivatives()


if __name__ == "__main__":
    main()
