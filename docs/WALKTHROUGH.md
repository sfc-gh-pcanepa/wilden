# Walkthrough

A step-by-step guide to running the Willdan CostPoint → Snowflake reference demo after
`./deploy.sh` completes. Every SQL block is paste-ready in a Snowsight worksheet.

> ALL DATA IS SYNTHETIC. Expected values below come from a fresh deploy.

Start each worksheet with:

```sql
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;
```

---

## 1. Source — the simulated CostPoint extract

CostPoint-style normalized tables live in `WILLDAN_DEMO.COSTPOINT_SIM`. The free-text columns are
deliberately messy (embedded commas, quotes, en-dashes, trailing spaces).

```sql
SELECT PROJ_ID, PROJ_NAME, PARENT_PROJ_ID, LVL_NO, CONTRACT_TYPE, CONTRACT_VALUE
FROM WILLDAN_DEMO.COSTPOINT_SIM.PROJ ORDER BY PROJ_ID;

SELECT COUNT(*) AS lines, SUM(LAB_AMT) AS amount
FROM WILLDAN_DEMO.COSTPOINT_SIM.LAB_HS WHERE TS_DT < '2026-11-01';
```

Expected: 26 PROJ rows (10 programs, 16 leaf projects); 14,099 labor lines / $11,054,531.00 before November.

## 2. Ingest — stage, bulk load, pipe

The extracts were unloaded as CSV to `@RAW.COSTPOINT_LANDING` (partitioned by month) and loaded
into all-string RAW tables with `_SOURCE_FILE` / `_LOADED_AT` lineage.

```sql
LIST @WILLDAN_DEMO.RAW.COSTPOINT_LANDING/ref/;

-- Raw line preview: note quoted fields with commas
SELECT $1 FROM @WILLDAN_DEMO.RAW.COSTPOINT_LANDING/ref/proj.csv
  (FILE_FORMAT => 'WILLDAN_DEMO.RAW.CSV_RAWLINE') LIMIT 5;

SELECT _SOURCE_FILE, COUNT(*) FROM WILLDAN_DEMO.RAW.LAB_HS_RAW GROUP BY 1 ORDER BY 1 DESC LIMIT 5;
```

### Live: a new monthly extract arrives

```sql
CALL WILLDAN_DEMO.RAW.SP_DEMO_DROP_NEW_EXTRACT();
-- returns lab_hs/period=2026-11/lab_hs_2026-11_<timestamp>.csv

ALTER PIPE WILLDAN_DEMO.RAW.LAB_HS_PIPE REFRESH PREFIX = 'period=2026-11/';

-- after a few seconds:
SELECT COUNT(*) FROM WILLDAN_DEMO.RAW.LAB_HS_RAW WHERE _SOURCE_FILE ILIKE '%period=2026-11%';
SELECT SYSTEM$PIPE_STATUS('WILLDAN_DEMO.RAW.LAB_HS_PIPE');
```

Expected: 55 November rows in RAW.

## 3. Transform — cleansing UDF and dynamic tables

```sql
SELECT WILLDAN_DEMO.CURATED.CLEAN_TEXT('Lighting Retrofit – Small Business, "Direct Install"  ');
-- Lighting Retrofit - Small Business Direct Install

SELECT NAME, TARGET_LAG_SEC, SCHEDULING_STATE:state::STRING AS STATE, LATEST_DATA_TIMESTAMP
FROM TABLE(WILLDAN_DEMO.INFORMATION_SCHEMA.DYNAMIC_TABLES())
QUALIFY ROW_NUMBER() OVER (PARTITION BY QUALIFIED_NAME ORDER BY LATEST_DATA_TIMESTAMP DESC NULLS LAST) = 1;
```

The dynamic tables refresh themselves (15-minute target lag). To show the new extract immediately:

```sql
ALTER DYNAMIC TABLE WILLDAN_DEMO.CURATED.FACT_LABOR REFRESH;
ALTER DYNAMIC TABLE WILLDAN_DEMO.ANALYTICS.PROJECT_BURN REFRESH;

SELECT COUNT(*), SUM(LABOR_COST) FROM WILLDAN_DEMO.CURATED.FACT_LABOR;
```

Expected: 14,099 rows / $11,054,531.00 at baseline → **14,154** rows after the November load.

```sql
SELECT PROJECT_ID, PROJECT_NAME, CONTRACT_VALUE, LABOR_TO_DATE, BURN_PCT, SCHEDULE_PCT, BURN_VS_SCHEDULE_GAP
FROM WILLDAN_DEMO.ANALYTICS.PROJECT_BURN WHERE AT_RISK ORDER BY BURN_VS_SCHEDULE_GAP DESC;
```

Expected at-risk projects: **2040.03** Plan Check Services, **2040.01** Smith Rd Design Phase 2,
**1001.03** Program Admin & Reporting.

Lineage and refresh history are also visible in Snowsight: open `ANALYTICS.PROJECT_BURN` → **Graph**.

## 4. Deliver — feeds, files, tasks, API

```sql
SELECT * FROM WILLDAN_DEMO.CURATED.FEED_ADAPTIVE_LABOR WHERE PERIOD = '2026-10' LIMIT 10;

CALL WILLDAN_DEMO.CURATED.SP_EXPORT_FEED('ADAPTIVE_LABOR', '2026-10');
-- SUCCESS: 32 rows -> @OUTBOUND/adaptive_labor/2026-10/adaptive_labor_2026-10.csv

CALL WILLDAN_DEMO.CURATED.SP_EXPORT_FEED('NOT_A_FEED', '2026-10');   -- rejected by allowlist

LIST @WILLDAN_DEMO.CURATED.OUTBOUND;
SELECT * FROM WILLDAN_DEMO.CURATED.EXPORT_LOG ORDER BY STARTED_AT DESC;
```

### Download the CSV (GET)

From the repository root with the Snowflake CLI:

```bash
mkdir -p exports
snow sql -c <connection> --role WILLDAN_DEMO_ADMIN -q \
  "GET @WILLDAN_DEMO.CURATED.OUTBOUND/adaptive_labor/2026-10/ 'file://$PWD/exports/'"
```

Header + 32 rows, 7 comma-separated fields per line, no stray delimiters from the free text.

### Month-end task graph

```sql
SHOW TASKS IN SCHEMA WILLDAN_DEMO.CURATED;
-- Root TASK_MONTH_END_REFRESH is suspended by design; run the graph once on demand:
EXECUTE TASK WILLDAN_DEMO.CURATED.TASK_MONTH_END_REFRESH;
```

The children export the prior calendar month relative to the run date; with the fixed 2026 data
they may log `SKIPPED` if that month has no rows.

### Push to a REST API

```sql
CALL WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API('PM_LABOR_DETAIL', '2026-10', '2040.03');
```

Posts the rows as JSON to `https://httpbin.org/post` (a public echo service standing in for a
downstream API) through external access integration `WILLDAN_DEMO_API_EAI`, verifies the echoed
row count, and logs to `EXPORT_LOG`.

## 5. Consume

### Snowflake Intelligence (CoWork)

Open Snowflake Intelligence (`https://ai.snowflake.com`) and select **Willdan Project Assistant**
(run `setup/01_admin_add_agent_to_si.sql` first if your account curates agents). Sample questions:

- Which projects are at risk of going over budget?
- Is there a change order that explains the Plan Check overrun?
- Which projects are at risk and is there a change order that explains it?
- What was total labor cost by business unit last month?
- What is utilization by employee title this period?
- What is our timesheet submission policy for month-end close?

The agent uses the semantic view `ANALYTICS.WILLDAN_PROJECT_LABOR_SV` for numbers and the Cortex
Search service `KNOWLEDGE.PROJECT_DOCS_SEARCH` for contracts, change orders, status reports and
policies — e.g. it should cite pending change order CO-03 for 2040.03 and approved CO-02 for 2040.01.

Search the documents directly:

```sql
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCS_SEARCH',
  '{"query":"change order plan check scope increase","columns":["TITLE","PROJ_ID","DOC_TYPE"],"limit":3}');
```

### Streamlit app

Snowsight → **Projects » Streamlit** → `WILLDAN_PROJECT_LABOR` (first open may take a minute
while the container starts).

- **Project health** — KPIs, burn-vs-schedule scatter (points above the diagonal are burning
  faster than schedule), at-risk table, monthly labor cost by business unit.
- **Deliver a feed** — pick a feed and period, preview rows, then *Export to stage*,
  *Send to API*, or *Download CSV*.
- **Pipeline** — export log, loaded files per source file, dynamic table status.

### Static HTML dashboard

```bash
SNOWFLAKE_DEFAULT_CONNECTION_NAME=<connection> uv run dashboard/build_dashboard.py
open willdan-dashboard.html
```

Writes a self-contained `willdan-dashboard.html` at the repo root (git-ignored).

### Excel

See [excel/excel-odbc-setup.md](../excel/excel-odbc-setup.md) for ODBC (DSN) and SQL API
(Power Query + programmatic access token) setup against the `WILLDAN_DEMO.EXCEL` views with the
read-only `WILLDAN_EXCEL_READER` role. Row counts: 16 / 404 / 1,540 at baseline, 16 / 418 / 1,595
after the November load.

## 6. Simulated live feed (optional)

A serverless task drops 25 synthetic timesheet lines (dated today) into the landing stage every
15 minutes and refreshes the pipe, so the dashboards move on their own.

```sql
CALL WILLDAN_DEMO.RAW.SP_SIMULATE_COSTPOINT_EXTRACT(25);              -- one batch now

ALTER TASK WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED RESUME;      -- start
ALTER TASK WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED SUSPEND;     -- stop
```

Simulated rows have `LAB_ID >= 900000000` and files named `lab_hs_sim_*.csv`.

## 7. Reset

```sql
CALL WILLDAN_DEMO.RAW.SP_DEMO_RESET();
```

Deletes November and simulated rows, suspends the feed task, truncates `EXPORT_LOG`, and refreshes
`FACT_LABOR` / `PROJECT_BURN`. `FACT_LABOR` returns to 14,099 rows. Staged files remain but are
not reloaded (they are in the pipe's load history). For a completely clean state, re-run `./deploy.sh`.

---

## What's included / Extending this demo

**Included:** simulated CostPoint source, file-based ingest (stage + COPY + pipe), SQL cleansing
and dynamic-table transforms, CSV feed export with audit log, task graph, REST API push via
external access, semantic view + Cortex Agent, Cortex Search over documents, Streamlit,
static HTML dashboard, Excel (ODBC and SQL API).

**Possible extensions (not built here):**

- **Box delivery via Openflow** — land exported feed files in a Box folder using an Openflow
  connector instead of (or in addition to) the internal stage.
- **Direct CostPoint connectivity** — replace file extracts with a database connector
  (e.g. Openflow, or a partner ELT tool) reading CostPoint's database or APIs, subject to your
  security and compliance review.
- **WBS row-level security** — a row access policy on `FACT_LABOR` / `PROJECT_BURN` keyed to
  program or PM so each user sees only their projects, across the agent, Streamlit and Excel.
- **Data sharing** — share curated views with partner or downstream Snowflake accounts using
  Secure Data Sharing or listings, with no file copies.
