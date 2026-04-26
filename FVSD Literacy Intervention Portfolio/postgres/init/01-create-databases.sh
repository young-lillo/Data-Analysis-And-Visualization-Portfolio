#!/bin/sh
set -eu

if ! psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='metabaseapp'" | grep -q 1; then
  psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE metabaseapp"
fi

if ! psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='fvsd_analytics'" | grep -q 1; then
  psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE fvsd_analytics"
fi
