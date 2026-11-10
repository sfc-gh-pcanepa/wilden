-- =====================================================================
-- 01_source.sql
-- Willdan Group demo: foundation + simulated Deltek CostPoint source.
-- ALL DATA IN THIS FILE IS SYNTHETIC. No real customers, employees,
-- projects or financials. Text is deliberately messy (commas, quotes,
-- en-dashes, trailing spaces) to exercise downstream cleansing.
-- Deterministic: RANDOM() calls are seeded, so a fresh deploy reproduces the
-- documented baseline (14,154 LAB_HS rows; 14,099 before Nov-2026).
-- =====================================================================
-- Prerequisite: setup/00_admin_setup.sql (role, warehouse, database).
USE ROLE WILLDAN_DEMO_ADMIN;
USE WAREHOUSE WILLDAN_WH;
USE DATABASE WILLDAN_DEMO;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.COSTPOINT_SIM;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.RAW;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.CURATED;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.APPS;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.KNOWLEDGE;
CREATE SCHEMA IF NOT EXISTS WILLDAN_DEMO.EXCEL;
USE SCHEMA WILLDAN_DEMO.COSTPOINT_SIM;

-- ---------------- CUST (synthetic) ----------------
CREATE OR REPLACE TABLE CUST (CUST_ID VARCHAR, CUST_NAME VARCHAR, CUST_TYPE VARCHAR, STATE_CD VARCHAR(2), ACTIVE_FL VARCHAR(1));
INSERT INTO CUST VALUES
 ('C0001','Pacific Coast Electric, Inc.','UTILITY','CA','Y'),
 ('C0002','Sunbelt Retail Group, "SRG"','RETAIL','TX','Y'),
 ('C0003','City of Riverbend   ','MUNICIPALITY','CA','Y'),
 ('C0004','State Dept. of Transportation – District 7','STATE_DOT','CA','Y'),
 ('C0005','Lakeview Unified School District','SCHOOL_DISTRICT','CA','Y'),
 ('C0006','Northeast Gas & Power Co.','UTILITY','NY','Y'),
 ('C0007','Town of Cedar Falls','MUNICIPALITY','AZ','Y'),
 ('C0008','Mid-Atlantic Power Authority','UTILITY','NJ','Y'),
 ('C0009','County of San Marco, "Public Works"','MUNICIPALITY','CA','Y'),
 ('C0010','Desert Valley Water & Light','UTILITY','NV','N');

-- ---------------- ORG (synthetic, 3 levels) ----------------
CREATE OR REPLACE TABLE ORG (ORG_ID VARCHAR, ORG_NAME VARCHAR, PARENT_ORG_ID VARCHAR, LVL_NO NUMBER, COMPANY_CD VARCHAR);
INSERT INTO ORG VALUES
 ('1','Willdan Energy Solutions',NULL,1,'WES'),
 ('1.10','WES – West Region','1',2,'WES'),
 ('1.10.100','WES West – Program Delivery','1.10',3,'WES'),
 ('1.10.200','WES West – Engineering Svcs','1.10',3,'WES'),
 ('1.20','WES – East Region','1',2,'WES'),
 ('1.20.100','WES East – Program Delivery','1.20',3,'WES'),
 ('2','Willdan Engineering',NULL,1,'WENG'),
 ('2.10','WENG – Municipal Services','2',2,'WENG'),
 ('2.10.100','WENG Muni – Plan Check','2.10',3,'WENG'),
 ('2.10.200','WENG Muni – Civil Design','2.10',3,'WENG'),
 ('3','Willdan Financial Services',NULL,1,'WFS'),
 ('3.10','WFS – Advisory','3',2,'WFS'),
 ('3.10.100','WFS Advisory – Rate Studies','3.10',3,'WFS'),
 ('4','Coastal Grid Partners (acq. 2025)',NULL,1,'CGP'),
 ('4.10','CGP – Grid Modernization','4',2,'CGP'),
 ('4.10.100','CGP Grid – DER Integration ','4.10',3,'CGP');

-- ---------------- EMPL (synthetic, 60 unique first+last) ----------------
CREATE OR REPLACE TABLE EMPL (EMPL_ID VARCHAR, FIRST_NAME VARCHAR, LAST_NAME VARCHAR, TITLE VARCHAR, BILL_RATE NUMBER(8,2),
  HOME_ORG_ID VARCHAR, HIRE_DT DATE, TERM_DT DATE, STATUS VARCHAR(1));
INSERT INTO EMPL
WITH n AS (SELECT SEQ4() AS i FROM TABLE(GENERATOR(ROWCOUNT => 60))),
f AS (SELECT ARRAY_CONSTRUCT('James','Maria','Robert','Linda','David','Priya','Michael','Elena','Kevin','Aisha','Thomas','Grace','Daniel','Sofia','Brian') a),
l AS (SELECT ARRAY_CONSTRUCT('Garcia','O''Brien','Nguyen','Smith, Jr.','Müller','Patel','Johnson','Kim','Rodriguez','Chen','Williams','Okafor','Martinez','Lee','Brown','Hernandez','Davis','Singh','Lopez','Walker') a),
t AS (SELECT ARRAY_CONSTRUCT('Principal Engineer','Senior Engineer','Project Manager','Engineer II','Energy Analyst','Technician') tt,
             ARRAY_CONSTRUCT(210,175,160,125,98,72) rr),
o AS (SELECT ARRAY_CONSTRUCT('1.10.100','1.10.200','1.20.100','2.10.100','2.10.200','3.10.100','4.10.100') oo)
SELECT 'E' || LPAD(i+1001,5,'0'),
       f.a[MOD(i,15)]::VARCHAR, l.a[MOD(i,20)]::VARCHAR,
       t.tt[MOD(i,6)]::VARCHAR, t.rr[MOD(i,6)]::NUMBER + MOD(i,3)*2,
       o.oo[MOD(i,7)]::VARCHAR,
       DATEADD(day, -MOD(i*137,3000), '2023-12-01'::DATE),
       CASE WHEN i IN (7,23,41,55) THEN DATEADD(day, MOD(i*53,400), '2024-06-01'::DATE) END,
       CASE WHEN i IN (7,23,41,55) THEN 'T' ELSE 'A' END
FROM n, f, l, t, o;

-- ---------------- PROJ (synthetic 2-level WBS) ----------------
CREATE OR REPLACE TABLE PROJ (PROJ_ID VARCHAR, PROJ_NAME VARCHAR, PARENT_PROJ_ID VARCHAR, LVL_NO NUMBER, CUST_ID VARCHAR, ORG_ID VARCHAR,
  PM_EMPL_ID VARCHAR, CONTRACT_TYPE VARCHAR, CONTRACT_VALUE NUMBER(14,2), START_DT DATE, END_DT DATE, ACTIVE_FL VARCHAR(1));
INSERT INTO PROJ VALUES
 ('2040','Riverbend Municipal Engineering, On-Call',NULL,1,'C0003','2.10','E01003','T&M',NULL,'2024-01-01','2028-06-30','Y'),
 ('2040.01','Smith Rd Design, Phase 2','2040',2,'C0003','2.10.200','E01003','FFP',1150000,'2024-03-04','2027-03-31','Y'),
 ('2040.02','Storm Drain Master Plan – Update','2040',2,'C0003','2.10.200','E01009','T&M',620000,'2024-06-03','2027-06-30','Y'),
 ('2040.03','Plan Check Services ','2040',2,'C0003','2.10.100','E01015','T&M',1400000,'2024-01-01','2027-08-24','Y'),
 ('1001','PCE Commercial Energy Efficiency Program',NULL,1,'C0001','1.10',  'E01021','CPFF',NULL,'2024-01-01','2027-12-31','Y'),
 ('1001.01','Lighting Retrofit – Small Business, "Direct Install"','1001',2,'C0001','1.10.100','E01021','CPFF',2200000,'2024-01-01','2027-12-31','Y'),
 ('1001.02','HVAC Tune-Up, Commercial','1001',2,'C0001','1.10.200','E01027','CPFF',1300000,'2024-06-03','2027-12-31','Y'),
 ('1001.03','Program Admin & Reporting','1001',2,'C0001','1.10.100','E01033','CPFF',1600000,'2024-03-04','2027-12-31','Y'),
 ('3010','SRG Retail Portfolio Energy Services',NULL,1,'C0002','1.20',  'E01039','FFP',NULL,'2024-09-02','2027-09-30','Y'),
 ('3010.01','Store Audits, Wave 1 – TX/OK','3010',2,'C0002','1.20.100','E01039','FFP',900000,'2024-09-02','2027-03-31','Y'),
 ('3010.02','Refrigeration Controls "Pilot"','3010',2,'C0002','1.20.100','E01045','T&M',540000,'2025-03-03','2027-09-30','Y'),
 ('4100','District 7 Corridor Program',NULL,1,'C0004','2.10',  'E01051','CPFF',NULL,'2024-04-01','2028-12-31','Y'),
 ('4100.01','SR-14 Corridor Inspection, CM Support','4100',2,'C0004','2.10.200','E01051','CPFF',1800000,'2024-04-01','2028-03-31','Y'),
 ('5200','Lakeview USD Facilities Energy',NULL,1,'C0005','1.10',  'E01057','FFP',NULL,'2025-01-06','2027-12-31','Y'),
 ('5200.01','Solar + Storage Feasibility, 6 Campuses','5200',2,'C0005','1.10.200','E01057','FFP',480000,'2025-01-06','2027-06-30','Y'),
 ('5200.02','HVAC Modernization – Design ','5200',2,'C0005','1.10.200','E01003','FFP',760000,'2025-06-02','2027-12-31','Y'),
 ('6300','NEGP Demand Response Programs',NULL,1,'C0006','1.20',  'E01009','T&M',NULL,'2024-07-01','2028-06-30','Y'),
 ('6300.01','Demand Response EM&V, "Summer Peak"','6300',2,'C0006','1.20.100','E01009','T&M',950000,'2024-07-01','2028-06-30','Y'),
 ('7400','Cedar Falls Utility Rate Study',NULL,1,'C0007','3.10',  'E01015','FFP',NULL,'2025-03-03','2026-12-31','Y'),
 ('7400.01','Water & Sewer Rate Study, FY27','7400',2,'C0007','3.10.100','E01015','FFP',310000,'2025-03-03','2026-12-31','Y'),
 ('8500','MAPA Grid Modernization',NULL,1,'C0008','4.10',  'E01021','CPFF',NULL,'2025-09-01','2028-08-31','Y'),
 ('8500.01','DER Interconnection Studies – Batch A','8500',2,'C0008','4.10.100','E01021','CPFF',1250000,'2025-09-01','2028-08-31','Y'),
 ('9600','San Marco Public Works On-Call',NULL,1,'C0009','2.10',  'E01027','T&M',NULL,'2024-09-02','2027-12-31','Y'),
 ('9600.01','Pavement Mgmt Program, "PMP" Update','9600',2,'C0009','2.10.200','E01027','T&M',420000,'2024-09-02','2027-06-30','Y'),
 ('1100','Desert Valley Grid Resilience',NULL,1,'C0010','4.10',  'E01033','CPFF',NULL,'2026-01-05','2028-12-31','Y'),
 ('1100.01','Wildfire Mitigation Plan, Grid Hardening','1100',2,'C0010','4.10.100','E01033','CPFF',880000,'2026-01-05','2028-12-31','Y');

-- ---------------- LAB_HS (synthetic timesheet lines) ----------------
-- Per-leaf target $ = contract * target burn; candidate lines are generated
-- randomly then kept in random order until cumulative $ reaches the target.
CREATE OR REPLACE TABLE LAB_HS (LAB_ID NUMBER, EMPL_ID VARCHAR, PROJ_ID VARCHAR, ORG_ID VARCHAR, ACCT_ID VARCHAR, TS_DT DATE,
  FY_CD VARCHAR(4), PD_NO NUMBER, HOURS NUMBER(5,1), BILL_RATE NUMBER(8,2), LAB_AMT NUMBER(14,2), STATUS VARCHAR(1), NOTES VARCHAR);
INSERT INTO LAB_HS
WITH p AS (
  SELECT PROJ_ID, ORG_ID, CONTRACT_VALUE, START_DT, END_DT,
         DATEDIFF(day, START_DT, '2026-11-05'::DATE) / DATEDIFF(day, START_DT, END_DT) AS sched,
         CASE PROJ_ID WHEN '2040.03' THEN 1.00 WHEN '2040.01' THEN 1.09
              WHEN '1001.03' THEN sched + 0.07 WHEN '1001.01' THEN sched - 0.20
              ELSE LEAST(0.97, sched - MOD(ABS(HASH(PROJ_ID)), 7) / 100.0) END AS tgt_burn,
         DATEDIFF(day, START_DT, LEAST(END_DT, '2026-11-04'::DATE)) AS span
  FROM PROJ WHERE LVL_NO = 2),
e AS (SELECT EMPL_ID, BILL_RATE, ROW_NUMBER() OVER (ORDER BY EMPL_ID) - 1 AS k FROM EMPL WHERE STATUS = 'A'),
g AS (SELECT SEQ4() AS s,
             UNIFORM(0,1000000,RANDOM(11)) r1, UNIFORM(0,1000000,RANDOM(22)) r2, UNIFORM(0,1000000,RANDOM(33)) r3,
             UNIFORM(0,1000000,RANDOM(44)) r4, UNIFORM(0,1000000,RANDOM(55)) r5, UNIFORM(0,1000000,RANDOM(66)) r6,
             UNIFORM(0,1000000,RANDOM(77)) r7
      FROM TABLE(GENERATOR(ROWCOUNT => 4000))),
c AS (
  SELECT p.PROJ_ID, p.ORG_ID, p.CONTRACT_VALUE * p.tgt_burn AS tgt_amt, g.*,
         DATEADD(day, MOD(g.r1, p.span + 1), p.START_DT) AS d0
  FROM p CROSS JOIN g),
d AS (
  SELECT c.*, CASE DAYOFWEEKISO(d0) WHEN 6 THEN DATEADD(day,-1,d0) WHEN 7 THEN DATEADD(day,-2,d0) ELSE d0 END AS ts_dt,
         2 + MOD(r3, 15) * 0.5 AS hrs, e.EMPL_ID, e.BILL_RATE
  FROM c JOIN e ON e.k = MOD(c.r2, 56)),
k AS (
  SELECT d.*, SUM(hrs * BILL_RATE) OVER (PARTITION BY PROJ_ID ORDER BY r7, s ROWS UNBOUNDED PRECEDING) AS cum
  FROM d QUALIFY cum <= tgt_amt)
SELECT ROW_NUMBER() OVER (ORDER BY ts_dt, PROJ_ID, s), EMPL_ID, PROJ_ID, ORG_ID,
       IFF(MOD(r4, 9) = 0, '5101-NB', '5100'), ts_dt, TO_VARCHAR(YEAR(ts_dt)), MONTH(ts_dt),
       hrs, BILL_RATE, hrs * BILL_RATE, IFF(MOD(r5, 40) = 0, 'P', 'A'),
       CASE MOD(r6, 8) WHEN 0 THEN NULL WHEN 1 THEN '' WHEN 2 THEN 'Site visit, client mtg'
            WHEN 3 THEN 'Revised "final" drawings per comments' WHEN 4 THEN 'QA/QC review – sheets 4-9'
            WHEN 5 THEN 'Travel, mileage not incl.' WHEN 6 THEN 'Coordination w/ city staff ' ELSE 'Report drafting' END
FROM k;
