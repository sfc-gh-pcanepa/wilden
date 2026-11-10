-- =====================================================================
-- setup/01_admin_add_agent_to_si.sql
-- ADMIN STEP (ACCOUNTADMIN), run AFTER deploy.sh has created the agent.
-- Makes WILLDAN_PROJECT_AGENT visible in Snowflake Intelligence (CoWork).
--
-- An account has at most one Snowflake Intelligence object. When created from
-- Snowsight it is always named SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT. If your
-- account has none, users see every agent they have USAGE on and this step is
-- optional; the CREATE below makes one (requires CREATE SNOWFLAKE INTELLIGENCE
-- ON ACCOUNT, which ACCOUNTADMIN has by default).
-- =====================================================================
USE ROLE ACCOUNTADMIN;

SHOW SNOWFLAKE INTELLIGENCES;

-- Uncomment ONLY if SHOW above returned no rows. Creating the object makes
-- agent visibility curated: agents not added to it disappear from CoWork.
-- CREATE SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
-- GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- ACCOUNTADMIN inherits USAGE on the agent via SYSADMIN -> WILLDAN_DEMO_ADMIN.
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT WILLDAN_DEMO.ANALYTICS.WILLDAN_PROJECT_AGENT;

-- Let the demo role see the object's agent list.
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE WILLDAN_DEMO_ADMIN;
