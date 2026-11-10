# /// script
# requires-python = ">=3.10"
# dependencies = ["snowflake-connector-python"]
# ///
"""Build willdan-dashboard.html from Snowflake (synthetic Willdan demo data).

Connection: SNOWFLAKE_DEFAULT_CONNECTION_NAME if set, otherwise the connector's
default connection from ~/.snowflake/connections.toml / config.toml.
Run:  uv run dashboard/build_dashboard.py   (or: python dashboard/build_dashboard.py)
"""
import datetime as dt
import decimal
import json
import os
from pathlib import Path

import snowflake.connector

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = Path(__file__).resolve().parent / "template.html"
OUT = ROOT / "willdan-dashboard.html"

QUERIES = {
    "projects": "SELECT * FROM WILLDAN_DEMO.ANALYTICS.PROJECT_BURN ORDER BY PROJECT_ID",
    "monthly": """SELECT PERIOD, BUSINESS_UNIT, SUM(LABOR_COST) AS LABOR_COST
                  FROM WILLDAN_DEMO.CURATED.FACT_LABOR
                  GROUP BY PERIOD, BUSINESS_UNIT ORDER BY PERIOD, BUSINESS_UNIT""",
    "exports": """SELECT RUN_ID, FEED, PERIOD, PATH, ROWS_EXPORTED, STATUS, MESSAGE, STARTED_AT, FINISHED_AT
                  FROM WILLDAN_DEMO.CURATED.EXPORT_LOG ORDER BY STARTED_AT DESC LIMIT 50""",
    "latest_load": "SELECT MAX(_LOADED_AT) AS LATEST_LOAD FROM WILLDAN_DEMO.RAW.LAB_HS_RAW",
}


def jsonable(v):
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (dt.datetime, dt.date, dt.time)):
        return v.isoformat()
    return v


def fetch(cur, sql):
    cur.execute(sql)
    cols = [c[0] for c in cur.description]
    return [{c: jsonable(v) for c, v in zip(cols, row)} for row in cur.fetchall()]


def main():
    kwargs = {"role": "WILLDAN_DEMO_ADMIN", "warehouse": "WILLDAN_WH"}
    conn_name = os.environ.get("SNOWFLAKE_DEFAULT_CONNECTION_NAME")
    if conn_name:
        kwargs["connection_name"] = conn_name
    with snowflake.connector.connect(**kwargs) as conn:
        cur = conn.cursor()
        cur.execute("USE WAREHOUSE WILLDAN_WH")
        data = {k: fetch(cur, q) for k, q in QUERIES.items()}
    data["latest_load"] = data["latest_load"][0]["LATEST_LOAD"] if data["latest_load"] else None
    data["generated_at"] = dt.datetime.now(dt.timezone.utc).isoformat()

    # Escape so the JSON can't terminate the <script> block.
    payload = json.dumps(data).replace("</", "<\\/").replace("<!--", "<\\!--")
    html = TEMPLATE.read_text().replace("__DATA_JSON__", payload)
    OUT.write_text(html)
    print(f"Wrote {OUT} ({len(data['projects'])} projects, {len(data['monthly'])} monthly rows, "
          f"{len(data['exports'])} export rows)")


if __name__ == "__main__":
    main()
