#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d social_media_analytics -f /sql/01-schema-and-load.sql
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d social_media_analytics -f /sql/02-analytics-views.sql
