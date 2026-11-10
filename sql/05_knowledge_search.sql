-- =====================================================================
-- 05_knowledge_search.sql
-- Unstructured KNOWLEDGE layer for the Willdan Group Snowflake demo.
-- ALL DOCUMENTS BELOW ARE SYNTHETIC / FICTIONAL, generated for demo
-- purposes only. They do not represent real Willdan contracts, clients,
-- employees or policies. Values are aligned to WILLDAN_DEMO.COSTPOINT_SIM.PROJ
-- (as of 2026-11-05, data through 2026-11-04).
-- =====================================================================
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;

CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.KNOWLEDGE;

CREATE OR REPLACE TABLE WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCUMENTS (
    DOC_ID   STRING,
    DOC_TYPE STRING,   -- CONTRACT | CHANGE_ORDER | STATUS_REPORT | POLICY
    PROJ_ID  STRING,   -- NULL for POLICY docs
    TITLE    STRING,
    DOC_DATE DATE,
    AUTHOR   STRING,
    BODY     STRING
);

INSERT INTO WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCUMENTS VALUES
-- ---------------------------------------------------------------- CONTRACTS
('DOC-001','CONTRACT','2040.03','City of Riverbend - Plan Check Services Task Order (T&M, NTE $1,400,000)','2024-01-01','Brian Brown',
$$TASK ORDER 2040.03 - PLAN CHECK SERVICES. Client: City of Riverbend (Customer C0003), under the Riverbend Municipal Engineering On-Call master agreement (project 2040). Period of performance: January 1, 2024 through August 24, 2027. Project Manager: Brian Brown.

Scope of Work: Willdan will provide building and civil plan check services on behalf of the City's Building & Safety and Public Works departments, including structural, architectural, MEP, and grading/drainage plan review. The base scope assumes up to two (2) review cycles per submittal and a standard 15 business-day turnaround. Additional review cycles, expedited (5-day) reviews, and counter services are outside the base scope and require a written change order.

Contract Type and Value: Time-and-Materials with a Not-to-Exceed (NTE) value of $1,400,000. Willdan shall not exceed the NTE without a fully executed change order. Billing rates: Principal Plans Examiner $195/hr, Senior Plans Examiner $164/hr, Plans Examiner $138/hr, Permit Technician $92/hr. Rates escalate 3% annually on January 1.

Billing Terms: Monthly invoicing in arrears, supported by CostPoint labor detail by employee and labor category. Payment net 30. Willdan shall notify the City in writing when billings reach 75% and 90% of the NTE.

Key Deliverables: plan review correction letters, monthly submittal log and turnaround report, quarterly performance summary.$$),

('DOC-002','CONTRACT','2040.01','City of Riverbend - Smith Rd Design, Phase 2 (FFP $1,150,000)','2024-03-04','Robert Nguyen',
$$TASK ORDER 2040.01 - SMITH ROAD DESIGN, PHASE 2. Client: City of Riverbend (C0003). Period of performance: March 4, 2024 through March 31, 2027. Project Manager: Robert Nguyen.

Scope: Final design (60/90/100% PS&E) for 1.8 miles of Smith Road widening, including roadway geometrics, signing and striping, signal modification at two intersections, utility coordination, and roadway drainage consistent with the 2019 Storm Drain Master Plan. The original drainage scope assumed connection to existing 36-inch trunk lines with no upsizing.

Contract Type and Value: Firm-Fixed-Price, $1,150,000. Willdan bears cost risk for effort beyond the fixed price unless scope changes are authorized by change order.

Billing Terms: Monthly milestone/percent-complete billing against the approved payment schedule: 60% PS&E (35%), 90% PS&E (30%), 100% PS&E (20%), bid support and design services during construction (15%). Retention of 5% released at acceptance of final PS&E.

Key Deliverables: 60/90/100% plans, specifications and estimates; drainage report; utility conflict matrix; bid-period RFI responses.$$),

('DOC-003','CONTRACT','2040.02','City of Riverbend - Storm Drain Master Plan Update (T&M, NTE $620,000)','2024-06-03','Kevin Rodriguez',
$$TASK ORDER 2040.02 - STORM DRAIN MASTER PLAN UPDATE. Client: City of Riverbend. Period: June 3, 2024 - June 30, 2027. PM: Kevin Rodriguez.

Scope: Update of the City's 2019 Storm Drain Master Plan, including GIS inventory update, hydrologic/hydraulic modeling for 10- and 100-year storms, capacity deficiency identification, a prioritized CIP, and a fee nexus study.

Contract Type: Time-and-Materials, NTE $620,000. Billing rates per the On-Call rate schedule (Senior Engineer $164/hr, Engineer $138/hr, GIS Analyst $110/hr). Monthly invoicing, net 30.

Deliverables: Draft and final master plan, hydraulic model files, CIP spreadsheet, City Council presentation.$$),

('DOC-004','CONTRACT','1001.01','PCE Lighting Retrofit - Small Business Direct Install (CPFF, $2,200,000)','2024-01-01','Priya Garcia',
$$PROGRAM CONTRACT 1001.01 - LIGHTING RETROFIT, SMALL BUSINESS DIRECT INSTALL. Client: Pacific Coast Electric, Inc. (C0001), under the PCE Commercial Energy Efficiency Program (1001). Period: January 1, 2024 - December 31, 2027. PM: Priya Garcia.

Scope: Willdan will market, audit, and install LED lighting retrofits for small commercial customers (<200 kW demand) at no cost to the customer. Includes customer outreach, walk-through audits, fixture procurement, subcontracted installation, post-install inspection, and savings documentation for regulatory reporting. Target: 1,400 sites and 18 GWh first-year savings.

Contract Type and Value: Cost-Plus-Fixed-Fee, total estimated value $2,200,000 inclusive of a fixed fee of 8% of estimated cost. Allowable costs include direct labor at actual payroll plus approved fringe/overhead rates, fixtures and materials at cost, and installation subcontracts.

Billing Terms: Monthly cost vouchers with provisional indirect rates; fee billed pro rata with cost. Materials billed upon delivery to site.

Key Deliverables: monthly program tracking report, quarterly savings claims, annual evaluation data request.$$),

('DOC-005','CONTRACT','1001.02','PCE HVAC Tune-Up, Commercial (CPFF, $1,300,000)','2024-06-03','Grace Johnson',
$$PROGRAM CONTRACT 1001.02 - COMMERCIAL HVAC TUNE-UP. Client: Pacific Coast Electric. Period: June 3, 2024 - December 31, 2027. PM: Grace Johnson.

Scope: Rooftop unit tune-up services (refrigerant charge, economizer repair, coil cleaning, thermostat programming) through a network of qualified HVAC contractors; Willdan manages contractor onboarding, QA/QC field inspections (10% sample), and savings calculations.

Contract Type: CPFF, estimated value $1,300,000 with 8% fixed fee. Monthly cost vouchers; contractor incentives passed through at cost.

Deliverables: contractor network roster, QA/QC inspection log, monthly and quarterly savings reports.$$),

('DOC-006','CONTRACT','1001.03','PCE Program Admin & Reporting (CPFF, $1,600,000)','2024-03-04','Robert Martinez',
$$PROGRAM CONTRACT 1001.03 - PROGRAM ADMINISTRATION & REPORTING. Client: Pacific Coast Electric. Period: March 4, 2024 - December 31, 2027. PM: Robert Martinez.

Scope: Portfolio-level administration for the PCE Commercial Energy Efficiency Program: program implementation plan, tracking database administration, regulatory filings, monthly/quarterly/annual reporting to PCE and the state commission, evaluator data requests, and program change management.

Contract Type and Value: Cost-Plus-Fixed-Fee, estimated value $1,600,000, fixed fee 7%. Labor billed at actual cost plus approved indirect rates.

Billing Terms: Monthly cost vouchers, net 30. The client acknowledges that administration effort is expected to be heavier in the first 18 months (system setup, implementation plan, baseline filings).

Deliverables: Program Implementation Plan, monthly dashboards, quarterly regulatory reports, annual report.$$),

('DOC-007','CONTRACT','6300.01','NEGP Demand Response EM&V "Summer Peak" (T&M, NTE $950,000)','2024-07-01','Kevin Rodriguez',
$$TASK ORDER 6300.01 - DEMAND RESPONSE EM&V, SUMMER PEAK. Client: Northeast Gas & Power Co. (C0006). Period: July 1, 2024 - June 30, 2028. PM: Kevin Rodriguez.

Scope: Evaluation, measurement and verification of NEGP residential and C&I demand response events for summer seasons 2024-2027: baseline methodology, interval-data load impact analysis, customer surveys, and annual impact reports.

Contract Type: T&M, NTE $950,000. Rates: Principal $210/hr, Senior Analyst $164/hr, Data Scientist $150/hr, Analyst $118/hr. Monthly invoicing, net 45.

Deliverables: annual EM&V plan, event-level impact estimates within 30 days of season end, final annual report.$$),

('DOC-008','CONTRACT','7400.01','Town of Cedar Falls - Water & Sewer Rate Study FY27 (FFP, $310,000)','2025-03-03','Brian Brown',
$$TASK ORDER 7400.01 - WATER & SEWER RATE STUDY, FY27. Client: Town of Cedar Falls, AZ (C0007). Period: March 3, 2025 - December 31, 2026. PM: Brian Brown.

Scope: Five-year financial plan, cost-of-service analysis, rate design alternatives, Prop 218-style public outreach support, and Council adoption hearings.

Contract Type: Firm-Fixed-Price, $310,000. Billing by milestone: data collection (15%), financial plan (25%), cost of service (25%), rate design (20%), adoption (15%).

Deliverables: draft and final rate study report, rate model, two Council presentations.$$),

('DOC-009','CONTRACT','8500.01','MAPA DER Interconnection Studies - Batch A (CPFF, $1,250,000)','2025-09-01','Priya Garcia',
$$TASK ORDER 8500.01 - DER INTERCONNECTION STUDIES, BATCH A. Client: Mid-Atlantic Power Authority (C0008). Period: September 1, 2025 - August 31, 2028. PM: Priya Garcia.

Scope: Feasibility, system impact, and facilities studies for up to 45 distributed energy resource interconnection requests in Batch A, including power-flow, short-circuit and protection coordination analysis.

Contract Type: CPFF, estimated value $1,250,000, fixed fee 9%. Monthly cost vouchers, net 30.

Deliverables: study reports per queue position, monthly queue status report, cost allocation summaries.$$),

('DOC-010','CONTRACT','4100.01','Caltrans District 7 - SR-14 Corridor Inspection & CM Support (CPFF, $1,800,000)','2024-04-01','Priya Williams',
$$TASK ORDER 4100.01 - SR-14 CORRIDOR INSPECTION, CM SUPPORT. Client: State Dept. of Transportation - District 7 (C0004). Period: April 1, 2024 - March 31, 2028. PM: Priya Williams.

Scope: Construction management support including resident engineer support, structures and roadway inspection, materials testing coordination, daily diaries, and contract change order analysis for the SR-14 corridor improvements.

Contract Type: CPFF, estimated value $1,800,000, fee 10% of direct labor and overhead. Monthly invoicing with certified payroll; field staff overtime requires prior written approval.

Deliverables: daily inspection reports, weekly statements of working days, monthly progress pay estimates support.$$),

('DOC-011','CONTRACT','3010.01','SRG Store Audits, Wave 1 - TX/OK (FFP, $900,000)','2024-09-02','Kevin Lopez',
$$TASK ORDER 3010.01 - STORE ENERGY AUDITS, WAVE 1 (TX/OK). Client: Sunbelt Retail Group, "SRG" (C0002). Period: September 2, 2024 - March 31, 2027. PM: Kevin Lopez.

Scope: ASHRAE Level II energy audits for 120 retail stores in Texas and Oklahoma, with measure recommendations for lighting, HVAC, refrigeration and controls.

Contract Type: FFP, $900,000 ($7,500 per store). Billed monthly per completed and accepted audit report. Net 45.

Deliverables: per-store audit reports, portfolio savings roll-up, Wave 2 recommendations.$$),

('DOC-012','CONTRACT','5200.01','Lakeview USD Solar + Storage Feasibility, 6 Campuses (FFP, $480,000)','2025-01-06','Grace Davis',
$$TASK ORDER 5200.01 - SOLAR + STORAGE FEASIBILITY. Client: Lakeview Unified School District (C0005). Period: January 6, 2025 - June 30, 2027. PM: Grace Davis.

Scope: Site assessments, PV and battery sizing, interconnection pre-screening, financial analysis (PPA vs. ownership), and board presentation for six campuses.

Contract Type: FFP, $480,000, billed by milestone per campus. Net 30.

Deliverables: six campus feasibility reports, district summary, board presentation.$$),

-- ---------------------------------------------------------------- CHANGE ORDERS
('DOC-013','CHANGE_ORDER','2040.03','Change Order CO-03 - Plan Check Additional Review Cycles & Expedited Reviews (PENDING)','2026-10-12','Brian Brown',
$$CHANGE ORDER REQUEST CO-03 - PROJECT 2040.03 PLAN CHECK SERVICES. Status: PENDING CLIENT APPROVAL (submitted to City of Riverbend Building Official October 12, 2026). Requested by: Brian Brown, PM.

Background: Since Q1 2026 the City has directed Willdan to perform third and fourth review cycles on a large share of submittals (approximately 41% of 2026 submittals required 3+ cycles versus the 2-cycle base assumption) and has requested expedited 5-business-day reviews for the Riverbend Commons mixed-use development and two school modernization projects. These services are outside the base scope defined in Task Order 2040.03.

Impact: As of the October 2026 billing, cumulative billings have effectively reached 100% of the $1,400,000 NTE, while the period of performance (through August 24, 2027) is only about 78% elapsed. Without a change order, Willdan must stop work or continue at risk.

Requested Change: Increase the NTE by $385,000 (from $1,400,000 to $1,785,000) to cover (a) additional review cycles, estimated $255,000, and (b) expedited review premium and overtime, estimated $130,000, through the end of the period of performance. No change to rates or end date.

Status Note: The NTE in CostPoint has NOT been raised. Until the City executes CO-03, all additional plan check effort is being performed at risk and labor hours are being tracked separately. Expected City Council consent agenda: December 2026.$$),

('DOC-014','CHANGE_ORDER','2040.01','Change Order CO-02 - Smith Rd Drainage Redesign (APPROVED)','2026-07-20','Robert Nguyen',
$$CHANGE ORDER CO-02 - PROJECT 2040.01 SMITH RD DESIGN, PHASE 2. Status: APPROVED and executed by the City of Riverbend on July 20, 2026.

Description: Following the 60% PS&E review, the City's updated Storm Drain Master Plan modeling (task order 2040.02) showed the existing 36-inch trunk line along Smith Road is undersized. The City directed Willdan to redesign roadway drainage with a 54-inch trunk line, two new catch basin laterals, and a revised hydrology report.

Value: Lump sum increase of $62,500 to the Firm-Fixed-Price, for a revised contract value of $1,212,500. Schedule: no extension; 90% PS&E milestone moved from June to September 2026.

Note on Budget Position: CO-02 covers the drainage redesign only. The project is currently tracking at roughly 109% of the original $1,150,000 contract value (approximately $1.25M of cost incurred), so even with CO-02 the project remains over budget by roughly $40,000-$45,000 due to additional utility coordination and repeated 90% plan resubmittals that are not compensable under the FFP. The approved CO-02 amount has not yet been loaded as a budget revision in CostPoint.$$),

('DOC-015','CHANGE_ORDER','6300.01','Change Order CO-01 - Additional Winter Peak Event Analysis (APPROVED, minor)','2026-02-09','Kevin Rodriguez',
$$CHANGE ORDER CO-01 - PROJECT 6300.01 DEMAND RESPONSE EM&V. Status: APPROVED by NEGP February 9, 2026.

Description: NEGP requested load impact analysis for three winter peak events in January 2026 that were not part of the summer-only scope. Value: $18,000 within the existing $950,000 NTE (no NTE increase; reallocation of contingency hours). No schedule impact.$$),

-- ---------------------------------------------------------------- STATUS REPORTS
('DOC-016','STATUS_REPORT','2040.03','Plan Check Services - Monthly Status Report, September 2026','2026-10-05','Brian Brown',
$$MONTHLY STATUS REPORT - 2040.03 PLAN CHECK SERVICES - SEPTEMBER 2026. PM: Brian Brown. Overall status: RED.

Budget: Cumulative cost is approximately 95% of the $1,400,000 NTE with roughly 75% of the schedule elapsed. Burn rate in Q3 averaged 1.6x plan due to repeat review cycles and expedited requests on Riverbend Commons.

Schedule: Average turnaround for standard reviews is 13 business days (target 15). Expedited reviews met the 5-day target on 9 of 11 submittals.

Staffing: 2 Senior Plans Examiners, 3 Plans Examiners, 1 Permit Technician. One examiner working overtime to support expedited reviews.

Risks: (1) NTE will be exhausted in October; (2) City continues to request 3rd/4th review cycles; (3) Staff burnout from sustained overtime.

Next Steps: Prepare and submit CO-03 for additional review cycles and expedited reviews; send 90% NTE notification letter to City; begin tracking out-of-scope hours separately.$$),

('DOC-017','STATUS_REPORT','2040.03','Plan Check Services - Monthly Status Report, October 2026','2026-11-03','Brian Brown',
$$MONTHLY STATUS REPORT - 2040.03 PLAN CHECK SERVICES - OCTOBER 2026. PM: Brian Brown. Overall status: RED - AT RISK.

Budget: Cumulative cost has reached approximately 100% of the $1,400,000 NTE while the period of performance (Jan 1, 2024 - Aug 24, 2027) is about 78% elapsed. Change Order CO-03 (+$385,000) was submitted October 12 and remains PENDING City approval; the NTE has not been raised in CostPoint.

Schedule: Turnaround performance remains within contract targets, but at the current burn rate the remaining 22% of the schedule is unfunded.

Staffing: Overtime reduced; one examiner temporarily reassigned to San Marco Public Works to limit at-risk hours.

Risks: Work is now proceeding at risk. If CO-03 is not approved by the December Council meeting, Willdan may need to suspend non-expedited reviews.

Next Steps: Meet with Building Official Nov 10; provide cycle-count analysis supporting CO-03; finance to flag the project in the Adaptive forecast as an EAC overrun pending CO.$$),

('DOC-018','STATUS_REPORT','2040.01','Smith Rd Design Phase 2 - Monthly Status Report, October 2026','2026-11-03','Robert Nguyen',
$$MONTHLY STATUS REPORT - 2040.01 SMITH RD DESIGN, PHASE 2 - OCTOBER 2026. PM: Robert Nguyen. Overall status: RED - OVER BUDGET.

Budget: Cost to date is approximately 109% of the original $1,150,000 FFP. Approved CO-02 (drainage redesign, +$62,500) brings the revised contract to $1,212,500, which still leaves the project roughly $40K+ over, with 100% PS&E and bid support remaining.

Schedule: 90% PS&E delivered September 2026. 100% PS&E planned January 2027; contract end March 31, 2027.

Staffing: Design team reduced to 1 senior engineer and 1 CAD technician to minimize further overrun.

Risks: Additional utility relocation conflicts (gas line at Station 42+50) could require more redesign; FFP overrun is a margin hit for the Engineering segment.

Next Steps: Load CO-02 into CostPoint budget; evaluate a claim for City-caused resubmittal delays; freeze scope through 100% PS&E.$$),

('DOC-019','STATUS_REPORT','1001.01','Lighting Retrofit Direct Install - Monthly Status Report, September 2026','2026-10-05','Priya Garcia',
$$MONTHLY STATUS REPORT - 1001.01 LIGHTING RETROFIT, SMALL BUSINESS DIRECT INSTALL - SEPTEMBER 2026. PM: Priya Garcia. Overall status: YELLOW.

Budget: Spend is running roughly 20 points behind schedule. This is an under-spend driven by delayed fixture deliveries, not a reduction in scope.

Supply Chain: Our primary LED troffer and high-bay supplier has pushed deliveries 10-14 weeks due to driver component shortages. Approximately 210 sites are audited and signed but awaiting fixtures. Materials are billed upon delivery, so cost recognition is lagging.

Staffing: Outreach and audit staff remain fully deployed; installation subcontractors have been scaled back pending materials.

Risks: Backlog may compress installations into Q1-Q2 2027, risking contractor capacity; year-end savings goal at risk.

Next Steps: Qualify a secondary fixture supplier; prioritize sites with fixtures in hand; update the forecast to shift spend into 2027.$$),

('DOC-020','STATUS_REPORT','1001.01','Lighting Retrofit Direct Install - Monthly Status Report, October 2026','2026-11-03','Priya Garcia',
$$MONTHLY STATUS REPORT - 1001.01 LIGHTING RETROFIT - OCTOBER 2026. PM: Priya Garcia. Overall status: YELLOW.

Budget: Spend remains about 20 points behind schedule on the $2,200,000 CPFF contract. First partial shipment from the primary supplier arrived October 28; secondary supplier qualified with first deliveries expected mid-November.

Schedule: 1,020 of 1,400 target sites audited; 640 installed. Install backlog of ~230 sites awaiting fixtures.

Risks: Under-spend is a timing issue; the client has been notified that monthly vouchers will spike in Dec 2026 - Feb 2027 as backlog clears.

Next Steps: Ramp installation crews in late November; re-baseline the spend curve with PCE.$$),

('DOC-021','STATUS_REPORT','1001.03','Program Admin & Reporting - Monthly Status Report, October 2026','2026-11-03','Robert Martinez',
$$MONTHLY STATUS REPORT - 1001.03 PROGRAM ADMIN & REPORTING - OCTOBER 2026. PM: Robert Martinez. Overall status: GREEN.

Budget: Spend is approximately 7 points ahead of schedule on the $1,600,000 CPFF contract. This is expected: administration work was front-loaded with the Program Implementation Plan, tracking database build-out, and baseline regulatory filings in 2024-2025, as anticipated in the contract.

Schedule: All monthly and Q3 regulatory reports delivered on time. Annual evaluator data request completed in September.

Staffing: Steady-state team of 1 program manager, 2 reporting analysts, 0.5 database administrator.

Risks: Low. Monitor so that the burn rate trends back to plan in 2027 as the work shifts to steady-state reporting.

Next Steps: Prepare 2027 program filing; reduce database administrator allocation to 0.25 FTE in Q1 2027.$$),

('DOC-022','STATUS_REPORT','6300.01','Demand Response EM&V - Monthly Status Report, October 2026','2026-11-03','Kevin Rodriguez',
$$MONTHLY STATUS REPORT - 6300.01 DEMAND RESPONSE EM&V - OCTOBER 2026. PM: Kevin Rodriguez. Overall status: GREEN.

Budget and schedule are tracking within tolerance. Summer 2026 season ended September 30; event-level impact estimates for 14 events are in QA and due to NEGP by October 30 (delivered October 29).

Staffing: 1 senior analyst, 2 data scientists. Risks: interval data gaps for ~3% of C&I accounts. Next steps: draft 2026 annual report, due January 2027.$$),

('DOC-023','STATUS_REPORT','4100.01','SR-14 Corridor Inspection - Monthly Status Report, September 2026','2026-10-05','Priya Williams',
$$MONTHLY STATUS REPORT - 4100.01 SR-14 CORRIDOR INSPECTION, CM SUPPORT - SEPTEMBER 2026. PM: Priya Williams. Overall status: GREEN.

Construction is 52% complete. Field staff: 1 structures rep, 3 roadway inspectors. Budget tracking near plan. Risks: contractor proposing night work in Q1 2027, which would require overtime authorization from District 7. Next steps: submit overtime authorization request; update staffing plan.$$),

-- ---------------------------------------------------------------- POLICIES
('DOC-024','POLICY',NULL,'Timesheet and Labor Charging Policy','2026-01-15','Corporate Finance - Project Accounting',
$$TIMESHEET AND LABOR CHARGING POLICY (Rev. 2026-01). Applies to all Willdan employees recording time in CostPoint.

1. Daily Entry: Employees must record hours in CostPoint daily, by end of each workday. Time must reflect actual hours worked on each project/task. Retroactive changes after timesheet approval require a correction reason and supervisor re-approval (DCAA-compliant audit trail).

2. Charging Accounts: Billable project work is charged to account 5100 (Direct Labor - Billable) against the correct project ID and labor category. Proposal work, training, internal meetings, business development and general administration are charged to account 5101-NB (Labor - Non-Billable) using the appropriate indirect project. Charging non-billable activity to a client project, or billable work to an indirect code, is prohibited.

3. Approval: Timesheets must be signed by employees and approved by supervisors/PMs by 5:00 PM local time every Friday. Unapproved lines remain in PENDING status and are excluded from labor distribution, invoicing, and the Adaptive export until approved.

4. Pending Lines: Finance runs a pending-line report each Monday; PMs are responsible for clearing pending lines on their projects within one business day.

5. Over-NTE Projects: Hours on projects whose funded value is exhausted (e.g., pending change orders) must still be recorded accurately; PMs must notify Project Accounting so the project can be flagged as working at risk.$$),

('DOC-025','POLICY',NULL,'CostPoint Month-End Close Calendar','2026-01-15','Corporate Finance - Controller',
$$COSTPOINT MONTH-END CLOSE CALENDAR (FY2026). Business days (BD) are counted from the first business day of the new month.

BD -1 (last business day of month): Timesheet cutoff at 12:00 PM PT. All timesheets for the period must be signed and approved. Pending lines after cutoff roll to the next period.
BD 0 / BD 1: Labor distribution run in CostPoint; accounts payable and subcontractor accruals posted; revenue recognition run for T&M, CPFF and FFP (percent-complete) projects.
BD 2: Export of actuals (labor, ODCs, revenue) from CostPoint to Adaptive Planning for forecast and variance reporting; PM project status reports due.
BD 3: Project Accounting reviews over-budget and over-NTE projects, change order status, and EAC updates with PMs.
BD 4: Invoicing released to clients.
BD 5: Controller sign-off; period closed in CostPoint.

Any project at or above 90% of contract value must have an EAC review documented by BD 3.$$);

-- Cortex Search service over document bodies
CREATE OR REPLACE CORTEX SEARCH SERVICE WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCS_SEARCH
  ON BODY
  ATTRIBUTES DOC_TYPE, PROJ_ID, TITLE, DOC_DATE
  WAREHOUSE = WILLDAN_WH
  TARGET_LAG = '1 hour'
AS
  SELECT BODY, DOC_ID, DOC_TYPE, PROJ_ID, TITLE, DOC_DATE, AUTHOR
  FROM WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCUMENTS;

-- Tests
-- SHOW CORTEX SEARCH SERVICES IN SCHEMA WILLDAN_DEMO.KNOWLEDGE;
-- SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCS_SEARCH',
--   '{"query":"change order plan check scope increase","columns":["TITLE","PROJ_ID","DOC_TYPE"],"limit":3}');
-- SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WILLDAN_DEMO.KNOWLEDGE.PROJECT_DOCS_SEARCH',
--   '{"query":"timesheet approval deadline","columns":["TITLE","DOC_TYPE"],"filter":{"@eq":{"DOC_TYPE":"POLICY"}},"limit":3}');
