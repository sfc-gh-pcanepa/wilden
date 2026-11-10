#!/usr/bin/env bash
# deploy.sh - deploy the Willdan CostPoint -> Snowflake reference demo.
#
# Prerequisite (once, as ACCOUNTADMIN): setup/00_admin_setup.sql
# Usage:   ./deploy.sh [connection_name]
#          (defaults to $SNOWFLAKE_DEFAULT_CONNECTION_NAME)
# Requires the Snowflake CLI (`snow`). Without a local install, run with uv:
#          SNOW="uvx --from snowflake-cli snow" ./deploy.sh my_conn
set -euo pipefail

CONN="${1:-${SNOWFLAKE_DEFAULT_CONNECTION_NAME:-}}"
if [[ -z "$CONN" ]]; then
  echo "Usage: $0 <connection_name>  (or set SNOWFLAKE_DEFAULT_CONNECTION_NAME)" >&2
  exit 1
fi
read -r -a SNOW_CMD <<< "${SNOW:-snow}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SQL_FILES=(
  01_source.sql
  02_ingest.sql
  03_transform.sql
  04_deliver.sql
  05_knowledge_search.sql
  06_semantic_view_agent.sql
  07_apps.sql
  08_excel.sql
  09_simulated_feed.sql
)

for f in "${SQL_FILES[@]}"; do
  echo "==> sql/$f"
  "${SNOW_CMD[@]}" sql -f "$ROOT/sql/$f" -c "$CONN"
done

echo "==> Streamlit app (app/streamlit)"
(cd "$ROOT/app/streamlit" && \
  "${SNOW_CMD[@]}" streamlit deploy --replace --prune -c "$CONN" \
    --role WILLDAN_DEMO_ADMIN --warehouse WILLDAN_WH)

echo "==> Verification"
"${SNOW_CMD[@]}" sql -c "$CONN" --role WILLDAN_DEMO_ADMIN --warehouse WILLDAN_WH -q "
SELECT COUNT(*) AS fact_labor_rows, SUM(LABOR_COST) AS labor_cost FROM WILLDAN_DEMO.CURATED.FACT_LABOR;
SELECT PROJECT_ID, PROJECT_NAME, BURN_PCT, SCHEDULE_PCT FROM WILLDAN_DEMO.ANALYTICS.PROJECT_BURN WHERE AT_RISK ORDER BY BURN_VS_SCHEDULE_GAP DESC;
SHOW CORTEX SEARCH SERVICES IN SCHEMA WILLDAN_DEMO.KNOWLEDGE;
SHOW AGENTS IN SCHEMA WILLDAN_DEMO.ANALYTICS;
SHOW STREAMLITS IN SCHEMA WILLDAN_DEMO.APPS;
"

cat <<'EOF'

Deploy complete. Expected baseline: FACT_LABOR 14,099 rows / $11,054,531.00;
at-risk projects 2040.01, 2040.03, 1001.03.

Next (ACCOUNTADMIN, optional): setup/01_admin_add_agent_to_si.sql to show the
agent in Snowflake Intelligence. Walkthrough: docs/WALKTHROUGH.md
EOF
