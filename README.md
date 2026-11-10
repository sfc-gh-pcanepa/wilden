# Willdan CostPoint → Snowflake reference demo

A self-contained, deployable reference demo that shows how project-accounting data from
**Deltek CostPoint** can flow through Snowflake end to end:

**Source → Ingest → Transform → Deliver → Consume**, plus a **Cortex Agent** (Snowflake
Intelligence / CoWork) that answers questions over both structured labor data and unstructured
project documents (**Cortex Search**), a **Streamlit** app, a static HTML dashboard, and **Excel**
access via ODBC or the SQL API.

> **ALL DATA IS SYNTHETIC.** Every customer, employee, project, timesheet line and document in
> this repository is fictional and generated for demonstration purposes. No real Willdan, Deltek,
> or client data is included.
>
> **Sample code, provided as-is.** This is a reference demo, not production software. It has no
> warranty or support commitment. Review security, cost and governance before adapting any part
> of it for real workloads.

## What it shows

| Stage | What happens | Key objects |
| --- | --- | --- |
| Source | Simulated CostPoint tables (CUST, ORG, EMPL, PROJ, LAB_HS) with deliberately messy text | `COSTPOINT_SIM.*` |
| Ingest | CSV extracts unloaded to an internal stage, bulk-loaded to all-string RAW tables with lineage columns; a pipe loads new monthly extracts | `RAW.COSTPOINT_LANDING`, `RAW.*_RAW`, `RAW.LAB_HS_PIPE` |
| Transform | Text-cleaning UDF + dynamic tables: dims, labor fact, project burn vs schedule | `CURATED.DIM_*`, `CURATED.FACT_LABOR`, `ANALYTICS.PROJECT_BURN` |
| Deliver | Feed views, CSV export proc with audit log, month-end task graph, REST API push | `CURATED.FEED_*`, `CURATED.SP_EXPORT_FEED`, `APPS.SP_SEND_FEED_TO_API` |
| Consume | Semantic view + Cortex Agent, Cortex Search over project docs, Streamlit, HTML dashboard, Excel | `ANALYTICS.WILLDAN_PROJECT_AGENT`, `KNOWLEDGE.PROJECT_DOCS_SEARCH`, `APPS.WILLDAN_PROJECT_LABOR`, `EXCEL.V_*` |

See [docs/architecture.md](docs/architecture.md) for the diagram and [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md)
for a step-by-step demo script.

## Prerequisites

- A Snowflake account where these are available in your region (or via
  [cross-region inference](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cross-region-inference)):
  Cortex AI functions, Cortex Analyst (semantic views), Cortex Search, Cortex Agents and
  Snowflake Intelligence (CoWork).
- Streamlit in Snowflake **container runtime** and a compute pool (the app uses the
  Snowflake-provided `SYSTEM_COMPUTE_POOL_CPU`; see `app/streamlit/snowflake.yml` to change it).
- Anaconda third-party package terms acknowledged in the account (the API-push procedure uses the
  `requests` package).
- Outbound access to `httpbin.org:443` (public echo service used as a stand-in REST endpoint).
- An **ACCOUNTADMIN** to run the one-time setup. Setup creates a role, warehouse, database,
  integration privilege and grants; everything else runs as the demo role `WILLDAN_DEMO_ADMIN`.
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`) with a
  configured connection, or [uv](https://docs.astral.sh/uv/) to run it without installing
  (`uvx --from snowflake-cli snow ...`).

## Deploy

1. **Admin setup (once, ACCOUNTADMIN)** — creates `WILLDAN_DEMO_ADMIN`, `WILLDAN_EXCEL_READER`,
   `WILLDAN_WH`, `WILLDAN_DEMO` and grants both roles to the user running it
   (edit `SET DEMO_USER` to grant to someone else):

   ```bash
   snow sql -f setup/00_admin_setup.sql -c <connection>
   ```

2. **Deploy the demo (as the user granted `WILLDAN_DEMO_ADMIN`)** — runs `sql/01..09` in order,
   deploys the Streamlit app, and prints verification queries:

   ```bash
   ./deploy.sh <connection>
   # or, without a local snow install:
   SNOW="uvx --from snowflake-cli snow" ./deploy.sh <connection>
   ```

   You can also run the `sql/` files manually in a Snowsight worksheet, in numeric order.

3. **Show the agent in Snowflake Intelligence (ACCOUNTADMIN, optional)**:

   ```bash
   snow sql -f setup/01_admin_add_agent_to_si.sql -c <connection>
   ```

Expected baseline after a fresh deploy: `CURATED.FACT_LABOR` = **14,099** rows /
**$11,054,531.00**; at-risk projects **2040.03, 2040.01, 1001.03**.

## Run the demo

Follow [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md).

## Reset

Returns the demo to the baseline (removes the November extract and simulated-feed rows, suspends
the feed task, truncates the export log, refreshes dynamic tables):

```sql
CALL WILLDAN_DEMO.RAW.SP_DEMO_RESET();
```

For a full rebuild, re-run `./deploy.sh` — every script is idempotent.

## Teardown

As ACCOUNTADMIN:

```bash
snow sql -f teardown/drop_all.sql -c <connection>
```

Drops the database, warehouse, external access integration and both roles, and removes the agent
from Snowflake Intelligence.

## Object inventory

| Object | Type | Created by |
| --- | --- | --- |
| `WILLDAN_DEMO_ADMIN`, `WILLDAN_EXCEL_READER` | Roles | setup/00 |
| `WILLDAN_WH` (XS, auto-suspend 60 s) | Warehouse | setup/00 |
| `WILLDAN_DEMO` | Database | setup/00 |
| `COSTPOINT_SIM.CUST/ORG/EMPL/PROJ/LAB_HS` | Tables (synthetic source) | 01 |
| `RAW.CSV_COSTPOINT`, `RAW.CSV_RAWLINE` | File formats | 02 |
| `RAW.COSTPOINT_LANDING`, `RAW.COSTPOINT_HOLDBACK` | Internal stages | 02 |
| `RAW.PROJ_RAW/ORG_RAW/EMPL_RAW/CUST_RAW/LAB_HS_RAW` | Tables | 02 |
| `RAW.LAB_HS_PIPE` | Pipe (manual refresh) | 02 |
| `RAW.SP_DEMO_DROP_NEW_EXTRACT()` | Procedure | 02 |
| `CURATED.CLEAN_TEXT(STRING)` | SQL UDF | 03 |
| `CURATED.DIM_ORG/DIM_EMPLOYEE/DIM_PROJECT/FACT_LABOR` | Dynamic tables | 03 |
| `ANALYTICS.PROJECT_BURN` | Dynamic table | 03 |
| `CURATED.FEED_ADAPTIVE_LABOR`, `CURATED.FEED_PM_LABOR_DETAIL` | Views | 04 |
| `CURATED.OUTBOUND`, `CURATED.EXPORT_LOG` | Stage, table | 04 |
| `CURATED.SP_EXPORT_FEED(STRING, STRING)` | Procedure | 04 |
| `CURATED.TASK_MONTH_END_REFRESH` (suspended) → `TASK_EXPORT_ADAPTIVE`, `TASK_EXPORT_PM_DETAIL` | Task graph | 04 |
| `KNOWLEDGE.PROJECT_DOCUMENTS` (25 synthetic docs) | Table | 05 |
| `KNOWLEDGE.PROJECT_DOCS_SEARCH` | Cortex Search service | 05 |
| `ANALYTICS.WILLDAN_PROJECT_LABOR_SV` | Semantic view | 06 |
| `ANALYTICS.WILLDAN_PROJECT_AGENT` | Cortex Agent | 06 |
| `APPS.DEMO_API_EGRESS`, `WILLDAN_DEMO_API_EAI` | Network rule, external access integration | 07 |
| `APPS.SP_SEND_FEED_TO_API(STRING, STRING, STRING)` | Python procedure | 07 |
| `APPS.WILLDAN_PROJECT_LABOR` | Streamlit app | deploy.sh |
| `EXCEL.V_PROJECT_BURN/V_MONTHLY_LABOR/V_LABOR_DETAIL_LAST_90D` | Views | 08 |
| `RAW.SP_SIMULATE_COSTPOINT_EXTRACT(NUMBER)`, `RAW.SP_DEMO_RESET()` | Procedures | 09 |
| `RAW.TASK_SIMULATE_COSTPOINT_FEED` (suspended) | Serverless task | 09 |

## Repository layout

```
.
├── README.md
├── deploy.sh                    # runs sql/01..09 + Streamlit deploy
├── setup/
│   ├── 00_admin_setup.sql       # ACCOUNTADMIN, once
│   └── 01_admin_add_agent_to_si.sql
├── sql/                         # deploy order, idempotent, run as WILLDAN_DEMO_ADMIN
│   ├── 01_source.sql  02_ingest.sql  03_transform.sql  04_deliver.sql
│   ├── 05_knowledge_search.sql  06_semantic_view_agent.sql
│   └── 07_apps.sql  08_excel.sql  09_simulated_feed.sql
├── app/streamlit/               # Streamlit in Snowflake (container runtime)
├── dashboard/                   # build_dashboard.py + template.html -> willdan-dashboard.html
├── excel/                       # ODBC + SQL API (Power Query) instructions
├── docs/                        # WALKTHROUGH.md, architecture.md
└── teardown/drop_all.sql
```

## Cost notes

- One **X-Small** warehouse with **60-second auto-suspend**; dynamic tables refresh on a
  15-minute target lag only while there are changes to process.
- The serverless simulated-feed task and the month-end task graph root are created
  **suspended**. Resume the feed only while presenting and suspend it afterwards (or call
  `SP_DEMO_RESET`, which suspends it).
- The Streamlit container runtime consumes compute-pool credits while running; it suspends after a
  period of viewer inactivity. Cortex Search, Analyst and Agent usage are billed per use.
- Run `teardown/drop_all.sql` when finished.

## Data dates

The synthetic data is anchored to a fixed "as of" date of **2026-11-05** (labor through
2026-11-04). Burn/schedule calculations use that fixed date, so results are stable regardless of
when you deploy. The simulated feed task, by contrast, stamps new lines with the current date.
