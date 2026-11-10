# Excel access to the Willdan demo (synthetic data)

Business-friendly views in `WILLDAN_DEMO.EXCEL` (no VARIANT columns):
`V_PROJECT_BURN`, `V_MONTHLY_LABOR`, `V_LABOR_DETAIL_LAST_90D`.

Read-only role `WILLDAN_EXCEL_READER` has USAGE on `WILLDAN_WH` / `WILLDAN_DEMO` / `EXCEL`
and SELECT on those 3 views only (created in `setup/00_admin_setup.sql`, grants in
`sql/08_excel.sql`). It is denied on `CURATED.FACT_LABOR`.

Row counts at baseline: 16 / 404 / 1,540. After the November extract is loaded: 16 / 418 / 1,595.

**Your account URL.** Run this and use `<org>-<account>.snowflakecomputing.com`:

```sql
SELECT LOWER(CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()) || '.snowflakecomputing.com' AS account_host;
```

Below, replace `<org>-<account>` with that value and `<YOUR_USER>` with your Snowflake user name.
The user must have `WILLDAN_EXCEL_READER` granted (setup grants it to the user who ran setup):

```sql
GRANT ROLE WILLDAN_EXCEL_READER TO USER <YOUR_USER>;   -- as ACCOUNTADMIN or role owner
```

## 1. ODBC driver

- Download: https://developers.snowflake.com/odbc/
- Docs: https://docs.snowflake.com/en/developer-guide/odbc/odbc

### macOS

1. Install iODBC (required by the Snowflake Mac driver): https://www.iodbc.org/ → `iODBC-SDK.pkg`.
2. Open `snowflake_odbc_mac-<version>.dmg`, run `snowflakeODBC_<version>.pkg` (admin password needed). Installs to `/opt/snowflake/snowflakeodbc`.
3. Create a DSN in `~/Library/ODBC/odbc.ini` (user) or `/Library/ODBC/odbc.ini` (system):

```ini
[ODBC Data Sources]
willdan = Snowflake

[willdan]
Driver        = /opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib
Description   = Willdan demo (synthetic)
server        = <org>-<account>.snowflakecomputing.com
uid           = <YOUR_USER>
authenticator = externalbrowser
warehouse     = WILLDAN_WH
role          = WILLDAN_EXCEL_READER
database      = WILLDAN_DEMO
schema        = EXCEL
```

4. Test: `"/Library/Application Support/iODBC/bin/iodbctest"` → connect string `dsn=willdan`.

### Windows

1. Download the **64-bit** MSI (match Excel's bitness) and run it.
2. Open **ODBC Data Sources (64-bit)** → User DSN or System DSN → Add → **SnowflakeDSIIDriver**.
3. Fill in: Data Source `willdan`, User `<YOUR_USER>`, Server `<org>-<account>.snowflakecomputing.com`,
   Database `WILLDAN_DEMO`, Schema `EXCEL`, Warehouse `WILLDAN_WH`, Role `WILLDAN_EXCEL_READER`,
   Authenticator `externalbrowser`. Click Test (a browser SSO window opens).

`externalbrowser` assumes SSO. For password/MFA or key-pair auth, see the ODBC docs.

## 2. Excel via ODBC

1. **Data > Get Data > From Other Sources > From ODBC**.
2. Pick DSN `willdan` (sign in via the browser window when prompted).
3. In the Navigator expand `WILLDAN_DEMO > EXCEL`, select a view (e.g. `V_PROJECT_BURN`), click **Load**.
4. To pick up new data later: **Data > Refresh All**.

## 3. Excel via SQL API (no driver) – `excel-sql-api.pq`

Power Query M that POSTs to `<AccountUrl>/api/v2/statements` with a programmatic access token (PAT)
and builds a typed table from `resultSetMetaData.rowType` + `data`. Reads partition 0 only (see comment in file).

### Create a PAT (the secret is shown only once)

```sql
ALTER USER <YOUR_USER> ADD PROGRAMMATIC ACCESS TOKEN willdan_excel_pat
  ROLE_RESTRICTION = 'WILLDAN_EXCEL_READER'
  DAYS_TO_EXPIRY = 7
  COMMENT = 'Willdan demo - Excel SQL API, read-only views';
```

See [ALTER USER … ADD PROGRAMMATIC ACCESS TOKEN](https://docs.snowflake.com/en/sql-reference/sql/alter-user-add-programmatic-access-token).
Store the secret in a password manager — never in the workbook or a repository.

### Network policy requirement

Per [Using programmatic access tokens](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens):
by default a human user (TYPE=PERSON) can generate a PAT without a network policy but **must be subject to a
network policy to authenticate** with it. Options:

- Activate a network policy (account- or user-level) that allows your Excel users' IP ranges; or
- An authentication policy with `PAT_POLICY = (NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED)`; or
- For short tests only, `MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT = <1-1440>` on the token (not recommended).

If an authentication policy limits `AUTHENTICATION_METHODS`, it must include `'PROGRAMMATIC_ACCESS_TOKEN'`.

### Configure in Excel

1. Data > Get Data > Launch Power Query Editor > **Manage Parameters > New**:
   `AccountUrl` (Text) = `https://<org>-<account>.snowflakecomputing.com`;
   `SnowflakeToken` (Text) = your PAT (each user enters their own; don't share a workbook with it filled in).
2. Home > New Source > Blank Query > Advanced Editor → paste `excel-sql-api.pq` → Done.
3. If prompted for credentials for the URL, choose **Anonymous** (auth is in the header) and set privacy level to Organizational.
4. Close & Load; refresh with **Data > Refresh All**.

### curl test

```bash
export SNOWFLAKE_PAT='<paste token>'   # or read from your secret manager
curl -s -X POST "https://<org>-<account>.snowflakecomputing.com/api/v2/statements" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -H "Authorization: Bearer $SNOWFLAKE_PAT" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  -d '{"statement":"SELECT COUNT(*) FROM WILLDAN_DEMO.EXCEL.V_PROJECT_BURN","warehouse":"WILLDAN_WH","role":"WILLDAN_EXCEL_READER","database":"WILLDAN_DEMO","schema":"EXCEL","timeout":60}'
```

Remove the token when done: `ALTER USER <YOUR_USER> REMOVE PROGRAMMATIC ACCESS TOKEN willdan_excel_pat;`

## 4. CSV export

```sql
CALL WILLDAN_DEMO.CURATED.SP_EXPORT_FEED('ADAPTIVE_LABOR','2026-10');
-- SUCCESS: 32 rows -> @OUTBOUND/adaptive_labor/2026-10/adaptive_labor_2026-10.csv
```

The stage path is **lowercase**. Download with the Snowflake CLI (from the repo root):

```bash
mkdir -p exports
snow sql -c <connection> --role WILLDAN_DEMO_ADMIN -q \
  "GET @WILLDAN_DEMO.CURATED.OUTBOUND/adaptive_labor/2026-10/ 'file://$PWD/exports/'"
```

Columns: `ENTITY,ORG_ID,PROJECT_ID,GL_ACCOUNT,PERIOD,HOURS,LABOR_COST` (header + 32 rows).
Open in Excel directly or via Data > From Text/CSV.
