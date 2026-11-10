// excel-sql-api.pq -- Power Query M: load WILLDAN_DEMO.EXCEL.V_PROJECT_BURN via the Snowflake SQL API.
// Synthetic Willdan demo data.
//
// Required Excel parameters (Data > Get Data > Launch Power Query Editor > Manage Parameters > New):
//   AccountUrl     (Text)  e.g. https://<org>-<account>.snowflakecomputing.com
//                  (find it: SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME();)
//   SnowflakeToken (Text)  programmatic access token for <YOUR_USER> -- NEVER hard-code it here.
//
// NOTE: The SQL API returns large results in multiple partitions. This query reads
// partition 0 only (data in the first response). For big results, loop over
// resultSetMetaData[partitionInfo] and GET
//   /api/v2/statements/{statementHandle}?partition=N
// for N = 1..count-1, then combine the rows. V_PROJECT_BURN is small and fits in partition 0.
let
    Body = Json.FromValue([
        statement = "SELECT * FROM WILLDAN_DEMO.EXCEL.V_PROJECT_BURN",
        timeout   = 60,
        warehouse = "WILLDAN_WH",
        role      = "WILLDAN_EXCEL_READER",
        database  = "WILLDAN_DEMO",
        schema    = "EXCEL"
    ]),
    Response = Json.Document(
        Web.Contents(AccountUrl, [
            RelativePath = "api/v2/statements",
            Headers = [
                #"Content-Type" = "application/json",
                Accept = "application/json",
                Authorization = "Bearer " & SnowflakeToken,
                #"X-Snowflake-Authorization-Token-Type" = "PROGRAMMATIC_ACCESS_TOKEN"
            ],
            Content = Body,
            Timeout = #duration(0, 0, 2, 0)
        ])
    ),
    RowType  = Response[resultSetMetaData][rowType],
    ColNames = List.Transform(RowType, each [name]),
    // SQL API returns every value as text; convert per Snowflake type.
    Convert = (meta as record, v as any) as any =>
        if v = null then null
        else let t = Text.Lower(meta[type]) in
            if t = "fixed" or t = "real" then Number.FromText(v, "en-US")
            else if t = "date" then Date.AddDays(#date(1970, 1, 1), Number.FromText(v))   // epoch days
            else if t = "boolean" then Text.Lower(v) = "true"
            else v,
    ToType = (meta as record) as type =>
        let t = Text.Lower(meta[type]) in
            if t = "fixed" or t = "real" then type nullable number
            else if t = "date" then type nullable date
            else if t = "boolean" then type nullable logical
            else type nullable text,
    Rows   = List.Transform(Response[data], (r) => List.Transform(List.Positions(RowType), (i) => Convert(RowType{i}, r{i}))),
    Raw    = Table.FromRows(Rows, ColNames),
    Typed  = Table.TransformColumnTypes(Raw, List.Transform(RowType, each {[name], ToType(_)}))
in
    Typed
