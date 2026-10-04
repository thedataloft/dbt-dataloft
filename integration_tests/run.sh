#!/usr/bin/env bash
# Run every macro case on one adapter.
#
#   ./run.sh                     # duckdb
#   DBT_BQ_PROJECT=my-project ./run.sh bigquery
#   DBT=/path/to/venv/bin/dbt ./run.sh duckdb
#
# Needs dbt-core 1.x with the adapter installed (requirements.txt). dbt 2.x (Fusion) is not
# what this was verified on.
set -euo pipefail
cd "$(dirname "$0")"
target="${1:-duckdb}"
dbt="${DBT:-dbt}"

"$dbt" deps --profiles-dir . --quiet
"$dbt" build --select tag:macro_cases --target "$target" --profiles-dir .
