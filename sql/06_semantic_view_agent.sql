-- 06_semantic_view_agent.sql : CONSUME layer (semantic view + Cortex agent)
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;

CREATE OR REPLACE SEMANTIC VIEW WILLDAN_DEMO.ANALYTICS.WILLDAN_PROJECT_LABOR_SV
  TABLES (
    fact_labor AS WILLDAN_DEMO.CURATED.FACT_LABOR PRIMARY KEY (LAB_ID)
      COMMENT = 'Timesheet labor lines (one row per employee/project/day entry)',
    dim_project AS WILLDAN_DEMO.CURATED.DIM_PROJECT PRIMARY KEY (PROJECT_ID)
      COMMENT = 'One row per LEAF project (WBS level 2) with parent program',
    dim_employee AS WILLDAN_DEMO.CURATED.DIM_EMPLOYEE PRIMARY KEY (EMPLOYEE_ID)
      COMMENT = 'Employees',
    project_burn AS WILLDAN_DEMO.ANALYTICS.PROJECT_BURN PRIMARY KEY (PROJECT_ID)
      COMMENT = 'Budget burn vs schedule per leaf project; source for burn, schedule and at-risk'
  )
  RELATIONSHIPS (
    labor_to_project AS fact_labor (PROJECT_ID) REFERENCES dim_project,
    labor_to_employee AS fact_labor (EMPLOYEE_ID) REFERENCES dim_employee,
    burn_to_project AS project_burn (PROJECT_ID) REFERENCES dim_project
  )
  FACTS (
    fact_labor.hours AS HOURS COMMENT = 'Hours on the labor line',
    fact_labor.labor_cost AS LABOR_COST COMMENT = 'Labor cost (hours x bill rate)',
    fact_labor.billable_hours_fact AS IFF(IS_BILLABLE, HOURS, 0),
    project_burn.contract_value_fact AS CONTRACT_VALUE,
    project_burn.budget_remaining_fact AS BUDGET_REMAINING,
    project_burn.burn_pct_fact AS BURN_PCT,
    project_burn.gap_fact AS BURN_VS_SCHEDULE_GAP
  )
  DIMENSIONS (
    dim_project.project_id AS PROJECT_ID COMMENT = 'Leaf project ID, e.g. 2040.03',
    dim_project.project_name AS PROJECT_NAME
      WITH SYNONYMS = ('project')
      COMMENT = 'LEAF project name, e.g. ''Plan Check Services''. Use this when the user names a specific project',
    dim_project.program_name AS PROGRAM_NAME
      COMMENT = 'PARENT program (WBS level 1) grouping several projects; do NOT filter named projects on this',
    dim_project.customer AS CUSTOMER_NAME WITH SYNONYMS = ('client') COMMENT = 'Customer / client name',
    dim_project.business_unit AS BUSINESS_UNIT WITH SYNONYMS = ('BU', 'segment') COMMENT = 'Business unit owning the project',
    dim_project.pm_name AS PM_NAME WITH SYNONYMS = ('project manager') COMMENT = 'Project manager',
    dim_project.contract_type AS CONTRACT_TYPE COMMENT = 'Contract type (T&M, fixed fee, NTE...)',
    dim_employee.employee_name AS EMPLOYEE_NAME COMMENT = 'Employee name',
    dim_employee.title AS TITLE COMMENT = 'Employee job title',
    fact_labor.period AS PERIOD COMMENT = 'Accounting period YYYY-MM',
    fact_labor.work_date AS WORK_DATE COMMENT = 'Date the labor was worked',
    fact_labor.is_billable AS IS_BILLABLE COMMENT = 'TRUE if billable labor',
    fact_labor.status AS STATUS COMMENT = 'Timesheet line status (e.g. approved / pending)',
    project_burn.at_risk AS AT_RISK COMMENT = 'TRUE when project is at risk of going over budget',
    project_burn.burn_pct AS BURN_PCT COMMENT = 'Percent of contract value consumed by labor',
    project_burn.schedule_pct AS SCHEDULE_PCT COMMENT = 'Percent of schedule elapsed'
  )
  METRICS (
    fact_labor.total_hours AS SUM(fact_labor.hours),
    fact_labor.total_labor_cost AS SUM(fact_labor.labor_cost) WITH SYNONYMS = ('labor spend', 'cost'),
    fact_labor.billable_hours AS SUM(fact_labor.billable_hours_fact),
    fact_labor.utilization_pct AS SUM(fact_labor.billable_hours_fact) / NULLIF(SUM(fact_labor.hours), 0) * 100
      COMMENT = 'Billable hours / total hours * 100',
    fact_labor.avg_bill_rate AS SUM(fact_labor.labor_cost) / NULLIF(SUM(fact_labor.hours), 0),
    fact_labor.headcount AS COUNT(DISTINCT fact_labor.EMPLOYEE_ID),
    project_burn.total_contract_value AS SUM(project_burn.contract_value_fact),
    project_burn.total_budget_remaining AS SUM(project_burn.budget_remaining_fact) WITH SYNONYMS = ('budget remaining'),
    project_burn.avg_burn_pct AS AVG(project_burn.burn_pct_fact),
    project_burn.avg_burn_vs_schedule_gap AS AVG(project_burn.gap_fact) WITH SYNONYMS = ('burn vs schedule gap')
  )
  COMMENT = 'Willdan project labor, utilization and budget burn (synthetic demo)'
  AI_SQL_GENERATION 'Today is 2026-11-05; labor data runs through 2026-11-04. A project is at risk when BURN_PCT is more than 5 points ahead of SCHEDULE_PCT or BURN_PCT is over 100 (use AT_RISK = TRUE). When the user names a project, filter on project_name (leaf), not program_name. Burn and schedule figures come from project_burn; list at-risk projects at leaf project level with project_id, project_name, burn_pct and schedule_pct.';

CREATE OR REPLACE AGENT WILLDAN_DEMO.ANALYTICS.WILLDAN_PROJECT_AGENT
  COMMENT = 'Willdan project labor, burn and project documents assistant'
  PROFILE = '{"display_name": "Willdan Project Assistant"}'
  FROM SPECIFICATION
$$
models:
  orchestration: auto
instructions:
  orchestration: >
    Use project_labor_analyst for all numbers: hours, labor cost, utilization, headcount, bill rates,
    contract value, budget burn, schedule %, and which projects are at risk.
    Use project_documents for scope, change orders, contract terms (NTE, billing), PM status narrative,
    and policy (timesheet, month-end close).
    For "why" questions or questions about at-risk projects that ask for explanation, change orders or context,
    use BOTH tools: first project_labor_analyst to identify the projects and their burn, then project_documents
    to find change orders / status reports for those projects (search by project name and ID).
    When the user names a project, refer to the leaf project name (e.g. Plan Check Services), not the program.
  response: >
    Be concise. Lead with the answer, include project IDs and key figures.
    Cite document titles (and dates) when using project_documents.
    Mention that labor data is through 2026-11-04.
  sample_questions:
    - question: "Which projects are at risk of going over budget?"
    - question: "Is there a change order that explains the Plan Check overrun?"
    - question: "Which projects are at risk and is there a change order that explains it?"
    - question: "What was total labor cost by business unit last month?"
    - question: "What is utilization by employee title this period?"
    - question: "What is our timesheet submission policy for month-end close?"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: project_labor_analyst
      description: "Structured labor, utilization, contract value and budget burn / at-risk metrics by project, program, customer, business unit, PM and employee."
  - tool_spec:
      type: data_to_chart
      name: data_to_chart
      description: "Generates charts from query results."
  - tool_spec:
      type: cortex_search
      name: project_documents
      description: "Project documents: scopes of work, change orders, contract terms (NTE, billing), PM status reports, and policies (timesheet, month-end close)."
tool_resources:
  project_labor_analyst:
    semantic_view: WILLDAN_DEMO.ANALYTICS.WILLDAN_PROJECT_LABOR_SV
    execution_environment:
      type: warehouse
      warehouse: WILLDAN_WH
  project_documents:
    search_service: WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCS_SEARCH
    id_column: DOC_ID
    title_column: TITLE
    max_results: 5
$$;

-- Making the agent visible in Snowflake Intelligence (CoWork) is an admin step:
-- run setup/01_admin_add_agent_to_si.sql as ACCOUNTADMIN after this file.
