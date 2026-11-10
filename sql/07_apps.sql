-- 07_apps.sql : APPS layer (external API delivery + Streamlit)
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.APPS;

CREATE OR REPLACE NETWORK RULE WILLDAN_DEMO.APPS.DEMO_API_EGRESS
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('httpbin.org:443');

-- Requires CREATE INTEGRATION ON ACCOUNT (granted in setup/00_admin_setup.sql).
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION WILLDAN_DEMO_API_EAI
  ALLOWED_NETWORK_RULES = (WILLDAN_DEMO.APPS.DEMO_API_EGRESS)
  ENABLED = TRUE;

CREATE OR REPLACE PROCEDURE WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API(FEED STRING, PERIOD STRING, PROJECT_CODE STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'requests')
HANDLER = 'run'
EXTERNAL_ACCESS_INTEGRATIONS = (WILLDAN_DEMO_API_EAI)
COMMENT = 'Willdan demo: POST a curated feed (allowlisted) for a period to a demo REST API (httpbin.org) and log to CURATED.EXPORT_LOG'
EXECUTE AS OWNER
AS
$$
import re
import datetime
import decimal
import requests
from snowflake.snowpark.functions import col

FEEDS = {
    "ADAPTIVE_LABOR": "WILLDAN_DEMO.CURATED.FEED_ADAPTIVE_LABOR",
    "PM_LABOR_DETAIL": "WILLDAN_DEMO.CURATED.FEED_PM_LABOR_DETAIL",
}
API_URL = "https://httpbin.org/post"
MAX_ROWS = 500


def _json_safe(v):
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (datetime.datetime, datetime.date, datetime.time)):
        return v.isoformat()
    return v


def _log(session, feed, period, rows, status, message, started):
    session.sql(
        "INSERT INTO WILLDAN_DEMO.CURATED.EXPORT_LOG "
        "(FEED, PERIOD, PATH, ROWS_EXPORTED, STATUS, MESSAGE, STARTED_AT, FINISHED_AT) "
        "SELECT ?, ?, ?, ?, ?, ?, TO_TIMESTAMP_LTZ(?), CURRENT_TIMESTAMP()",
        params=[feed, period, API_URL, rows, status, (message or "")[:4000], started.isoformat()],
    ).collect()


def run(session, feed, period, project_code):
    started = datetime.datetime.now(datetime.timezone.utc)
    feed_u = (feed or "").strip().upper()
    if not period:
        first = datetime.date.today().replace(day=1)
        period = (first - datetime.timedelta(days=1)).strftime("%Y-%m")
    result = {"feed": feed_u, "period": period, "project_code": project_code, "url": API_URL}
    try:
        if feed_u not in FEEDS:
            raise ValueError(f"Feed not allowed: {feed}")
        if not re.fullmatch(r"\d{4}-\d{2}", period):
            raise ValueError(f"Invalid period (YYYY-MM): {period}")
        df = session.table(FEEDS[feed_u]).filter(col("PERIOD") == period)
        if project_code:
            df = df.filter(col("PROJECT_ID") == project_code)
        rows = [{k: _json_safe(v) for k, v in r.as_dict().items()} for r in df.limit(MAX_ROWS).collect()]
        n = len(rows)
        if n == 0:
            result.update(status="SKIPPED", row_count=0, message="No rows for filter")
        else:
            payload = {"feed": feed_u, "period": period, "project_code": project_code, "row_count": n, "rows": rows}
            resp = requests.post(API_URL, json=payload, timeout=30)
            resp.raise_for_status()
            echoed = resp.json().get("json", {}).get("row_count")
            if echoed != n:
                raise RuntimeError(f"API echo mismatch: sent {n}, got {echoed}")
            result.update(status="SUCCESS", row_count=n, http_status=resp.status_code,
                          message=f"POSTed {n} rows; API confirmed row_count={echoed}")
    except Exception as e:
        result.update(status="FAILED", row_count=0, message=str(e))
    _log(session, feed_u, period, result["row_count"], result["status"], result["message"], started)
    return result
$$;

-- Tests (run manually), then clear the log:
-- CALL WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API('PM_LABOR_DETAIL','2026-10','2040.03');
-- CALL WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API('ADAPTIVE_LABOR','2026-10',NULL);
-- CALL WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API('BAD_FEED','2026-10',NULL);
-- DELETE FROM WILLDAN_DEMO.CURATED.EXPORT_LOG;

-- Streamlit WILLDAN_PROJECT_LABOR is deployed from app/streamlit/ by deploy.sh:
--   snow streamlit deploy --replace --prune -c <connection>
