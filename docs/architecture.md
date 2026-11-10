# Architecture

All data is synthetic. Object names below are the ones created by `sql/01..09`.

```mermaid
flowchart LR
  subgraph SRC["1 · Source (simulated CostPoint)"]
    CP["COSTPOINT_SIM<br/>CUST · ORG · EMPL · PROJ · LAB_HS"]
    SIM["RAW.TASK_SIMULATE_COSTPOINT_FEED<br/>(serverless, suspended)"]
  end

  subgraph ING["2 · Ingest (RAW)"]
    LAND[("@RAW.COSTPOINT_LANDING<br/>ref/*.csv · lab_hs/period=YYYY-MM/")]
    HOLD[("@RAW.COSTPOINT_HOLDBACK<br/>Nov-2026 extract")]
    PIPE["RAW.LAB_HS_PIPE"]
    RAWT["RAW.*_RAW<br/>all STRING + _SOURCE_FILE/_LOADED_AT"]
  end

  subgraph TRN["3 · Transform (dynamic tables)"]
    UDF["CURATED.CLEAN_TEXT()"]
    DIMS["CURATED.DIM_ORG · DIM_EMPLOYEE · DIM_PROJECT"]
    FACT["CURATED.FACT_LABOR<br/>(15 min lag)"]
    BURN["ANALYTICS.PROJECT_BURN<br/>(burn vs schedule, AT_RISK)"]
  end

  subgraph DEL["4 · Deliver"]
    FEEDS["CURATED.FEED_ADAPTIVE_LABOR<br/>CURATED.FEED_PM_LABOR_DETAIL"]
    EXP["CURATED.SP_EXPORT_FEED<br/>+ TASK_MONTH_END_REFRESH graph"]
    OUT[("@CURATED.OUTBOUND<br/>CSV files")]
    API["APPS.SP_SEND_FEED_TO_API<br/>via WILLDAN_DEMO_API_EAI"]
    LOG["CURATED.EXPORT_LOG"]
  end

  subgraph CON["5 · Consume"]
    DOCS["KNOWLEDGE.PROJECT_DOCUMENTS"]
    CSS["KNOWLEDGE.PROJECT_DOCS_SEARCH<br/>(Cortex Search)"]
    SV["ANALYTICS.WILLDAN_PROJECT_LABOR_SV<br/>(semantic view)"]
    AGENT["ANALYTICS.WILLDAN_PROJECT_AGENT<br/>Snowflake Intelligence"]
    ST["APPS.WILLDAN_PROJECT_LABOR<br/>(Streamlit)"]
    XL["EXCEL.V_* views<br/>ODBC / SQL API"]
    HTML["dashboard/build_dashboard.py<br/>→ HTML"]
  end

  CP -- "COPY INTO @stage" --> LAND
  CP --> HOLD
  SIM --> CP
  SIM --> LAND
  HOLD -- "SP_DEMO_DROP_NEW_EXTRACT" --> LAND
  LAND -- "bulk COPY" --> RAWT
  LAND --> PIPE --> RAWT
  RAWT --> UDF --> DIMS --> FACT --> BURN
  RAWT --> FACT
  FACT --> FEEDS --> EXP --> OUT
  FEEDS --> API --> EXT(["REST endpoint<br/>(httpbin.org stand-in)"])
  EXP --> LOG
  API --> LOG
  FACT --> SV
  BURN --> SV
  DOCS --> CSS
  SV --> AGENT
  CSS --> AGENT
  BURN --> ST
  FACT --> ST
  BURN --> XL
  FACT --> XL
  BURN --> HTML
```

## Flow summary

1. **Source** — `01_source.sql` builds a CostPoint-shaped, deterministic synthetic dataset
   (2-level WBS, 3-level org, ~14k timesheet lines through 2026-11-04).
2. **Ingest** — `02_ingest.sql` unloads extracts to an internal stage (history by month; November
   held back), bulk-loads RAW tables, and creates a pipe for subsequent monthly files.
3. **Transform** — `03_transform.sql` cleans text and builds the dimension/fact/burn dynamic
   tables, which refresh incrementally as new RAW rows land.
4. **Deliver** — `04_deliver.sql` and `07_apps.sql` produce allowlisted feed files and API pushes,
   both audited in `EXPORT_LOG`, orchestrated by a task graph.
5. **Consume** — `05`/`06` add Cortex Search and the semantic view + agent; `08` adds Excel views
   and a read-only role; the Streamlit app and HTML dashboard read the curated layer.
