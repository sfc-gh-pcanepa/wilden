-- 08_excel.sql : Excel-facing views + read-only role (Willdan demo, synthetic data)
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;

CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.EXCEL COMMENT = 'Business-friendly views for Excel (ODBC / SQL API)';

CREATE OR REPLACE VIEW WILLDAN_DEMO.EXCEL.V_PROJECT_BURN AS
SELECT
    PROJECT_ID            AS "Project ID",
    PROJECT_NAME          AS "Project Name",
    PROGRAM_NAME          AS "Program Name",
    CUSTOMER_NAME         AS "Customer Name",
    BUSINESS_UNIT         AS "Business Unit",
    PM_NAME               AS "Project Manager",
    CONTRACT_TYPE         AS "Contract Type",
    CONTRACT_VALUE        AS "Contract Value",
    START_DATE            AS "Start Date",
    END_DATE              AS "End Date",
    LABOR_TO_DATE         AS "Labor To Date",
    LABOR_LAST_30D        AS "Labor Last 30 Days",
    PENDING_LABOR         AS "Pending Labor",
    HOURS_TO_DATE         AS "Hours To Date",
    BUDGET_REMAINING      AS "Budget Remaining",
    BURN_PCT              AS "Burn Pct",
    SCHEDULE_PCT          AS "Schedule Pct",
    BURN_VS_SCHEDULE_GAP  AS "Burn vs Schedule Gap",
    AT_RISK               AS "At Risk",
    AS_OF_DATE            AS "As Of Date"
FROM WILLDAN_DEMO.ANALYTICS.PROJECT_BURN;

CREATE OR REPLACE VIEW WILLDAN_DEMO.EXCEL.V_MONTHLY_LABOR AS
SELECT
    f.PERIOD                                         AS "Period",
    f.BUSINESS_UNIT                                  AS "Business Unit",
    f.PROJECT_ID                                     AS "Project ID",
    p.PROJECT_NAME                                   AS "Project Name",
    SUM(f.HOURS)                                     AS "Hours",
    SUM(IFF(f.IS_BILLABLE, f.HOURS, 0))              AS "Billable Hours",
    SUM(f.LABOR_COST)                                AS "Labor Cost"
FROM WILLDAN_DEMO.CURATED.FACT_LABOR f
LEFT JOIN WILLDAN_DEMO.CURATED.DIM_PROJECT p ON p.PROJECT_ID = f.PROJECT_ID
GROUP BY f.PERIOD, f.BUSINESS_UNIT, f.PROJECT_ID, p.PROJECT_NAME;

CREATE OR REPLACE VIEW WILLDAN_DEMO.EXCEL.V_LABOR_DETAIL_LAST_90D AS
SELECT
    f.WORK_DATE       AS "Work Date",
    f.PERIOD          AS "Period",
    f.BUSINESS_UNIT   AS "Business Unit",
    f.PROJECT_ID      AS "Project ID",
    p.PROJECT_NAME    AS "Project Name",
    f.EMPLOYEE_ID     AS "Employee ID",
    e.EMPLOYEE_NAME   AS "Employee Name",
    e.TITLE           AS "Title",
    f.HOURS           AS "Hours",
    f.BILL_RATE       AS "Bill Rate",
    f.LABOR_COST      AS "Labor Cost",
    f.IS_BILLABLE     AS "Billable",
    f.STATUS          AS "Status",
    f.GL_ACCOUNT      AS "GL Account",
    f.NOTES           AS "Notes"
FROM WILLDAN_DEMO.CURATED.FACT_LABOR f
LEFT JOIN WILLDAN_DEMO.CURATED.DIM_PROJECT  p ON p.PROJECT_ID  = f.PROJECT_ID
LEFT JOIN WILLDAN_DEMO.CURATED.DIM_EMPLOYEE e ON e.EMPLOYEE_ID = f.EMPLOYEE_ID
WHERE f.WORK_DATE >= DATEADD(day, -90, '2026-11-05'::DATE);

-- Read-only role: views only (owner's-rights views; no grants on CURATED/ANALYTICS needed)
-- Role WILLDAN_EXCEL_READER is created (and granted to the demo user) in setup/00_admin_setup.sql.
GRANT USAGE ON WAREHOUSE WILLDAN_WH           TO ROLE WILLDAN_EXCEL_READER;
GRANT USAGE ON DATABASE WILLDAN_DEMO          TO ROLE WILLDAN_EXCEL_READER;
GRANT USAGE ON SCHEMA WILLDAN_DEMO.EXCEL      TO ROLE WILLDAN_EXCEL_READER;
GRANT SELECT ON VIEW WILLDAN_DEMO.EXCEL.V_PROJECT_BURN          TO ROLE WILLDAN_EXCEL_READER;
GRANT SELECT ON VIEW WILLDAN_DEMO.EXCEL.V_MONTHLY_LABOR         TO ROLE WILLDAN_EXCEL_READER;
GRANT SELECT ON VIEW WILLDAN_DEMO.EXCEL.V_LABOR_DETAIL_LAST_90D TO ROLE WILLDAN_EXCEL_READER;

-- Verification
-- USE ROLE WILLDAN_EXCEL_READER;
-- SELECT COUNT(*) FROM WILLDAN_DEMO.EXCEL.V_PROJECT_BURN;
-- SELECT COUNT(*) FROM WILLDAN_DEMO.EXCEL.V_MONTHLY_LABOR;
-- SELECT COUNT(*) FROM WILLDAN_DEMO.EXCEL.V_LABOR_DETAIL_LAST_90D;
-- SELECT COUNT(*) FROM WILLDAN_DEMO.CURATED.FACT_LABOR;  -- expected to fail
-- USE ROLE WILLDAN_DEMO_ADMIN;
