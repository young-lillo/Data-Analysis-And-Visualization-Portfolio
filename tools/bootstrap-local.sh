#!/usr/bin/env sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKBOOK_PATH="$PROJECT_ROOT/docs/Education_Management_Dataset.xlsx"
VENV_PATH="$PROJECT_ROOT/.venv"

if [ ! -f "$WORKBOOK_PATH" ]; then
  echo "Workbook not found at docs/Education_Management_Dataset.xlsx" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  echo "Python was not found in PATH." >&2
  exit 1
fi

if [ ! -d "$VENV_PATH" ]; then
  "$PYTHON_BIN" -m venv "$VENV_PATH"
fi

"$VENV_PATH/bin/python" -m pip install --upgrade pip
"$VENV_PATH/bin/python" -m pip install -r "$PROJECT_ROOT/requirements.txt"
"$VENV_PATH/bin/python" "$PROJECT_ROOT/tools/build-fvsd-prepared-exports.py"

echo "Prepared exports generated in docs/assets/exports"

if [ "${1:-}" != "--skip-docker" ]; then
  cd "$PROJECT_ROOT"
  docker compose up -d
  echo "Local stack started. Open http://localhost:3000"
fi
