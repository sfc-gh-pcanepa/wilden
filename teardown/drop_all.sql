-- =====================================================================
-- teardown/drop_all.sql
-- Removes EVERYTHING the Willdan reference demo created. Run as ACCOUNTADMIN.
-- Irreversible. The account-level Snowflake Intelligence object itself is left
-- in place (other agents may use it); only this demo's agent is removed.
-- =====================================================================
USE ROLE ACCOUNTADMIN;

-- 1. Stop scheduled work
ALTER TASK IF EXISTS WILLDAN_DEMO.RAW.TASK_SIMULATE_COSTPOINT_FEED SUSPEND;
ALTER TASK IF EXISTS WILLDAN_DEMO.CURATED.TASK_MONTH_END_REFRESH SUSPEND;
ALTER TASK IF EXISTS WILLDAN_DEMO.CURATED.TASK_EXPORT_ADAPTIVE SUSPEND;
ALTER TASK IF EXISTS WILLDAN_DEMO.CURATED.TASK_EXPORT_PM_DETAIL SUSPEND;

-- 2. Remove the agent from Snowflake Intelligence (errors if the object does
--    not exist or the agent was never added -- safe to ignore).
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  DROP AGENT WILLDAN_DEMO.ANALYTICS.WILLDAN_PROJECT_AGENT;

-- 3. Objects
DROP DATABASE IF EXISTS WILLDAN_DEMO;            -- schemas, DTs, agent, search, Streamlit, stages
DROP INTEGRATION IF EXISTS WILLDAN_DEMO_API_EAI; -- external access integration
DROP WAREHOUSE IF EXISTS WILLDAN_WH;

-- 4. Roles
DROP ROLE IF EXISTS WILLDAN_EXCEL_READER;
DROP ROLE IF EXISTS WILLDAN_DEMO_ADMIN;
