"""Shared config for the Airbnb cook analysis."""

from pathlib import Path
import os

DATASET_DIR = Path(
    os.environ.get(
        "AIRBNB_DATASET_DIR",
        "D:/VScode/Test/Data set/B\u00e0i 16_ Travel & Hospitality",
    )
)
OUTPUT_DIR = Path(__file__).resolve().parent
LISTINGS = DATASET_DIR / "Listings.csv"
REVIEWS = DATASET_DIR / "Reviews.csv"

CITY_CURRENCY = {
    "Paris": "EUR",
    "Rome": "EUR",
    "New York": "USD",
    "Sydney": "AUD",
    "Rio de Janeiro": "BRL",
    "Istanbul": "TRY",
    "Mexico City": "MXN",
    "Bangkok": "THB",
    "Cape Town": "ZAR",
    "Hong Kong": "HKD",
}

FX_LOCAL_PER_USD = {
    "USD": 1.0,
    "EUR": 0.877,
    "AUD": 1.452,
    "BRL": 5.158,
    "TRY": 7.009,
    "MXN": 21.487,
    "THB": 31.294,
    "ZAR": 16.459,
    "HKD": 7.756,
}

NUMERIC_FIELDS = [
    "accommodates",
    "bedrooms",
    "minimum_nights",
    "maximum_nights",
    "review_scores_rating",
    "review_scores_accuracy",
    "review_scores_cleanliness",
    "review_scores_checkin",
    "review_scores_communication",
    "review_scores_location",
    "review_scores_value",
    "host_total_listings_count",
]

BINARY_FIELDS = [
    "host_is_superhost",
    "host_has_profile_pic",
    "host_identity_verified",
    "instant_bookable",
]

AMENITY_FLAGS = [
    "Wifi",
    "Kitchen",
    "Air conditioning",
    "Washer",
    "Heating",
    "Pool",
    "Free parking",
    "Elevator",
    "Gym",
    "Hot tub",
    "Breakfast",
    "Pets allowed",
]
