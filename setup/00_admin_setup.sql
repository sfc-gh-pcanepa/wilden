-- =====================================================================
-- setup/00_admin_setup.sql
-- One-time account setup for the Willdan CostPoint -> Snowflake reference demo.
-- Run ONCE as ACCOUNTADMIN (Snowsight worksheet or:
--   snow sql -f setup/00_admin_setup.sql -c <connection>).
-- Safe to re-run (IF NOT EXISTS / idempotent grants).
--
-- Creates: role WILLDAN_DEMO_ADMIN (owns everything the demo builds),
--          role WILLDAN_EXCEL_READER (read-only Excel views),
--          warehouse WILLDAN_WH (XS, auto-suspend 60s),
--          database WILLDAN_DEMO (owned by WILLDAN_DEMO_ADMIN),
--          and the account-level grants the deploy scripts need.
-- =====================================================================
USE ROLE ACCOUNTADMIN;

-- The user who will deploy and present the demo. Defaults to you.
SET DEMO_USER = CURRENT_USER();

-- ---------------------------------------------------------------------
-- 1. Roles
-- ---------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS WILLDAN_DEMO_ADMIN
  COMMENT = 'Owns and deploys the Willdan CostPoint reference demo (synthetic data)';
CREATE ROLE IF NOT EXISTS WILLDAN_EXCEL_READER
  COMMENT = 'Excel read-only access to WILLDAN_DEMO.EXCEL views';

-- Keep custom roles in the system role hierarchy (best practice).
GRANT ROLE WILLDAN_DEMO_ADMIN   TO ROLE SYSADMIN;
GRANT ROLE WILLDAN_EXCEL_READER TO ROLE WILLDAN_DEMO_ADMIN;

GRANT ROLE WILLDAN_DEMO_ADMIN   TO USER IDENTIFIER($DEMO_USER);
GRANT ROLE WILLDAN_EXCEL_READER TO USER IDENTIFIER($DEMO_USER);

-- ---------------------------------------------------------------------
-- 2. Warehouse (owned by the demo role so it can grant USAGE to the Excel role)
-- ---------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS WILLDAN_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Willdan reference demo (synthetic data)';
GRANT OWNERSHIP ON WAREHOUSE WILLDAN_WH TO ROLE WILLDAN_DEMO_ADMIN COPY CURRENT GRANTS;

-- ---------------------------------------------------------------------
-- 3. Database (owned by the demo role; schemas are created by sql/01_source.sql)
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS WILLDAN_DEMO
  COMMENT = 'Willdan CostPoint -> Snowflake reference demo. ALL DATA IS SYNTHETIC.';
GRANT OWNERSHIP ON DATABASE WILLDAN_DEMO TO ROLE WILLDAN_DEMO_ADMIN COPY CURRENT GRANTS;

-- ---------------------------------------------------------------------
-- 4. Account-level privileges
-- ---------------------------------------------------------------------
-- Tasks: month-end task graph (04_deliver.sql) and serverless simulated feed (09).
GRANT EXECUTE TASK         ON ACCOUNT TO ROLE WILLDAN_DEMO_ADMIN;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE WILLDAN_DEMO_ADMIN;

-- External access integration WILLDAN_DEMO_API_EAI (07_apps.sql) is created by
-- the demo role, so it needs CREATE INTEGRATION. If your security team prefers
-- not to grant this, create the network rule + EAI here as ACCOUNTADMIN instead
-- and GRANT USAGE ON INTEGRATION WILLDAN_DEMO_API_EAI TO ROLE WILLDAN_DEMO_ADMIN.
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE WILLDAN_DEMO_ADMIN;

-- Cortex AI (Cortex Analyst, Cortex Search, Cortex Agents). CORTEX_USER is
-- granted to PUBLIC by default; granted explicitly here in case it was revoked.
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE WILLDAN_DEMO_ADMIN;

-- Streamlit container runtime: the app owner needs USAGE on the compute pool.
-- app/streamlit/snowflake.yml uses the Snowflake-provided SYSTEM_COMPUTE_POOL_CPU.
-- UNVERIFIED: whether USAGE on SYSTEM_COMPUTE_POOL_CPU must be granted explicitly
-- (it may already be available to all roles). If you use your own pool, replace
-- the name here and in snowflake.yml. Comment this out if the grant errors.
GRANT USAGE ON COMPUTE POOL SYSTEM_COMPUTE_POOL_CPU TO ROLE WILLDAN_DEMO_ADMIN;
-- Only needed if you create your OWN compute pool / services with endpoints:
-- GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE WILLDAN_DEMO_ADMIN;

-- Snowflake Intelligence (CoWork): visibility is managed by the account-level
-- Snowflake Intelligence object. Adding the agent requires MODIFY on that object
-- plus USAGE on the agent, so it is done after deploy in
-- setup/01_admin_add_agent_to_si.sql (run as ACCOUNTADMIN).

-- ---------------------------------------------------------------------
-- 5. Defaults for the demo user (Snowflake Intelligence uses the user's
--    DEFAULT_ROLE / DEFAULT_WAREHOUSE when a session starts). Optional.
-- ---------------------------------------------------------------------
-- ALTER USER IDENTIFIER($DEMO_USER) SET DEFAULT_ROLE = WILLDAN_DEMO_ADMIN DEFAULT_WAREHOUSE = WILLDAN_WH;

SHOW GRANTS TO ROLE WILLDAN_DEMO_ADMIN;
