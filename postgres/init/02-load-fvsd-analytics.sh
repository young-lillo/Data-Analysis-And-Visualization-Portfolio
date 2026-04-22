#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d fvsd_analytics -f /sql/01-schema-and-load.sql
