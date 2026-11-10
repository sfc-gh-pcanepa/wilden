-- =====================================================================
-- 09_simulated_feed.sql  -  Willdan Group demo, SIMULATED COSTPOINT FEED
-- ALL DATA IS SYNTHETIC. Generated timesheet lines are random rows built
-- from synthetic EMPL / PROJ; no real Willdan data is used.
--
-- Each run: insert N synthetic lines into COSTPOINT_SIM.LAB_HS (the "source"),
-- unload exactly those lines as a CostPoint-style CSV into the landing stage,
-- then refresh the stage directory + pipe. FACT_LABOR / PROJECT_BURN (15 min
-- lag) pick them up automatically.
--
-- Marker for generated rows: LAB_ID >= 900000000 (LAB_ID is NUMBER in source).
-- Files: lab_hs/period=YYYY-MM/lab_hs_sim_<YYYYMMDDHH24MISS>.csv
-- =====================================================================
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;
USE SCHEMA WILLDAN_DEMO.RAW;

-- ---------------------------------------------------------------------
-- 1. Generator proc
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE WILLDAN_DEMO.RAW.SP_SIMULATE_COSTPOINT_EXTRACT(N_LINES NUMBER DEFAULT 25)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Synthetic demo: generates N synthetic CostPoint timesheet lines, writes them to COSTPOINT_SIM.LAB_HS and drops a CSV extract in landing (LAB_ID >= 900000000)'
EXECUTE AS OWNER
AS
$$
DECLARE
  n       INTEGER;
  base_id INTEGER;
  ts      DATE;
  period  STRING;
  file_nm STRING;
  stmt    STRING;
  ins     INTEGER;
BEGIN
  n := GREATEST(1, LEAST(COALESCE(N_LINES, 25), 1000));
  -- weekend -> previous Friday
  ts := CASE DAYOFWEEKISO(CURRENT_DATE()) WHEN 6 THEN DATEADD(day, -1, CURRENT_DATE())
                                          WHEN 7 THEN DATEADD(day, -2, CURRENT_DATE())
                                          ELSE CURRENT_DATE() END;
  period  := TO_CHAR(:ts, 'YYYY-MM');
  file_nm := 'lab_hs_sim_' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS') || '.csv';
  SELECT GREATEST(899999999, COALESCE(MAX(LAB_ID), 0)) INTO :base_id
    FROM WILLDAN_DEMO.COSTPOINT_SIM.LAB_HS WHERE LAB_ID >= 900000000;

  -- a/b. new synthetic lines (same conventions as 01_source.sql)
  INSERT INTO WILLDAN_DEMO.COSTPOINT_SIM.LAB_HS
    (LAB_ID, EMPL_ID, PROJ_ID, ORG_ID, ACCT_ID, TS_DT, FY_CD, PD_NO, HOURS, BILL_RATE, LAB_AMT, STATUS, NOTES)
  WITH e AS (SELECT EMPL_ID, BILL_RATE, ROW_NUMBER() OVER (ORDER BY EMPL_ID) - 1 AS k,
                    COUNT(*) OVER () AS cnt
             FROM WILLDAN_DEMO.COSTPOINT_SIM.EMPL WHERE STATUS = 'A'),
       p AS (SELECT PROJ_ID, ORG_ID, ROW_NUMBER() OVER (ORDER BY PROJ_ID) - 1 AS k, COUNT(*) OVER () AS cnt
             FROM WILLDAN_DEMO.COSTPOINT_SIM.PROJ
             WHERE LVL_NO = 2 AND START_DT <= :ts AND END_DT >= :ts),
       g AS (SELECT SEQ4() AS s,
                    UNIFORM(0,1000000,RANDOM()) r1, UNIFORM(0,1000000,RANDOM()) r2,
                    UNIFORM(0,1000000,RANDOM()) r3, UNIFORM(0,1000000,RANDOM()) r4,
                    UNIFORM(0,1000000,RANDOM()) r5, UNIFORM(0,1000000,RANDOM()) r6
             FROM TABLE(GENERATOR(ROWCOUNT => 1000))
             QUALIFY ROW_NUMBER() OVER (ORDER BY s) <= :n),
       r AS (SELECT g.*, 2 + MOD(g.r3, 15) * 0.5 AS hrs, e.EMPL_ID, e.BILL_RATE, p.PROJ_ID, p.ORG_ID
             FROM g
             JOIN e ON e.k = MOD(g.r1, e.cnt)
             JOIN p ON p.k = MOD(g.r2, p.cnt))
  SELECT :base_id + ROW_NUMBER() OVER (ORDER BY s), EMPL_ID, PROJ_ID, ORG_ID,  -- project org, matches history
         IFF(MOD(r4, 9) = 0, '5101-NB', '5100'), :ts, TO_VARCHAR(YEAR(:ts)), MONTH(:ts),
         hrs, BILL_RATE, hrs * BILL_RATE, IFF(MOD(r5, 40) = 0, 'P', 'A'),
         CASE MOD(r6, 8) WHEN 0 THEN NULL WHEN 1 THEN '' WHEN 2 THEN 'Site visit, client mtg'
              WHEN 3 THEN 'Revised "final" drawings per comments' WHEN 4 THEN 'QA/QC review – sheets 4-9'
              WHEN 5 THEN 'Travel, mileage not incl.' WHEN 6 THEN 'Coordination w/ city staff ' ELSE 'Report drafting' END
  FROM r;
  ins := SQLROWCOUNT;

  -- c. unload exactly those rows (path/ids are proc-generated values only)
  stmt := 'COPY INTO @WILLDAN_DEMO.RAW.COSTPOINT_LANDING/lab_hs/period=' || period || '/' || file_nm ||
          ' FROM (SELECT * FROM WILLDAN_DEMO.COSTPOINT_SIM.LAB_HS WHERE LAB_ID > ' || base_id ||
          ' AND LAB_ID <= ' || (base_id + ins) || ' ORDER BY LAB_ID)' ||
          ' FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = ''"'' COMPRESSION = NONE NULL_IF = (''''))' ||
          ' HEADER = TRUE SINGLE = TRUE';
  EXECUTE IMMEDIATE :stmt;

  -- d. directory + pipe refresh (sequential, after the file exists)
  ALTER STAGE WILLDAN_DEMO.RAW.COSTPOINT_LANDING REFRESH;
  stmt := 'ALTER PIPE WILLDAN_DEMO.RAW.LAB_HS_PIPE REFRESH PREFIX = ''period=' || period || '/''';
  EXECUTE IMMEDIATE :stmt;

  RETURN 'Generated ' || ins || ' lines -> lab_hs/period=' || period || '/' || file_nm;
END;
$$;

-- ---------------------------------------------------------------------
-- 2. Serverless task (created SUSPENDED; resume ~30-60 min before demo)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TASK WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED
  SCHEDULE = '15 MINUTE'
  USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
  COMMENT = 'Synthetic demo: simulates a CostPoint extract job dropping 25 labor lines every 15 min'
AS
  CALL WILLDAN_DEMO.RAW.SP_SIMULATE_COSTPOINT_EXTRACT(25);
-- ALTER TASK WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED RESUME;   -- before demo
-- ALTER TASK WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED SUSPEND;  -- after demo

-- ---------------------------------------------------------------------
-- 3. Demo reset proc
--    Staged files are left in place (REMOVE unsupported in procs); the pipe
--    will not reload them because they are in its load history.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE WILLDAN_DEMO.RAW.SP_DEMO_RESET()
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Demo: removes synthetic Nov-2026 + simulated-feed rows, suspends sim task, resets downstream objects'
EXECUTE AS CALLER
AS
$$
DECLARE
  deleted INTEGER DEFAULT 0;
  sim_raw INTEGER DEFAULT 0;
  sim_src INTEGER DEFAULT 0;
  log_msg STRING DEFAULT 'EXPORT_LOG truncated';
  task_msg STRING DEFAULT 'sim task suspended';
  dt_msg  STRING DEFAULT 'FACT_LABOR + PROJECT_BURN refreshed';
BEGIN
  BEGIN
    ALTER TASK IF EXISTS WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED SUSPEND;
  EXCEPTION WHEN OTHER THEN
    task_msg := 'sim task suspend skipped (' || SQLERRM || ')';
  END;
  DELETE FROM WILLDAN_DEMO.RAW.LAB_HS_RAW WHERE _SOURCE_FILE ILIKE '%lab_hs_sim_%';
  sim_raw := SQLROWCOUNT;
  DELETE FROM WILLDAN_DEMO.RAW.LAB_HS_RAW WHERE _SOURCE_FILE ILIKE '%period=2026-11%';
  deleted := SQLROWCOUNT;
  DELETE FROM WILLDAN_DEMO.COSTPOINT_SIM.LAB_HS WHERE LAB_ID >= 900000000;
  sim_src := SQLROWCOUNT;
  BEGIN
    TRUNCATE TABLE IF EXISTS WILLDAN_DEMO.CURATED.EXPORT_LOG;
  EXCEPTION WHEN OTHER THEN
    log_msg := 'EXPORT_LOG skipped (' || SQLERRM || ')';
  END;
  BEGIN
    ALTER DYNAMIC TABLE WILLDAN_DEMO.CURATED.FACT_LABOR REFRESH;
    ALTER DYNAMIC TABLE WILLDAN_DEMO.ANALYTICS.PROJECT_BURN REFRESH;
  EXCEPTION WHEN OTHER THEN
    dt_msg := 'DT refresh skipped (' || SQLERRM || ')';
  END;
  RETURN 'Deleted ' || deleted || ' Nov-2026 LAB_HS_RAW rows; ' || sim_raw || ' sim RAW rows; ' ||
         sim_src || ' sim LAB_HS rows; ' || task_msg || '; ' || log_msg || '; ' || dt_msg;
END;
$$;
