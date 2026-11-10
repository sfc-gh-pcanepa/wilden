import os

import altair as alt
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Willdan Project Labor", layout="wide")

conn = st.connection(
    "snowflake",
    connection_name=os.getenv("SNOWFLAKE_DEFAULT_CONNECTION_NAME") or "default",
)

# Allowlist: feed name -> view. Only these identifiers are ever placed in SQL text.
FEEDS = {
    "ADAPTIVE_LABOR": "WILLDAN_DEMO.CURATED.FEED_ADAPTIVE_LABOR",
    "PM_LABOR_DETAIL": "WILLDAN_DEMO.CURATED.FEED_PM_LABOR_DETAIL",
}


session = conn.session()


@st.cache_data(ttl=300, show_spinner=False)
def _cached(sql, params):
    return session.sql(sql, params=list(params) if params else None).to_pandas()


def q(sql, params=None, ttl=300):
    # Bound (?) params via Snowpark; ttl=0 bypasses the cache for actions/fresh reads.
    if ttl == 0:
        return session.sql(sql, params=params).to_pandas()
    return _cached(sql, tuple(params) if params else None)


st.title("Willdan Project Labor")
tab_health, tab_feed, tab_pipe = st.tabs(["Project health", "Deliver a feed", "Pipeline"])

with tab_health:
    burn = q(
        """SELECT PROJECT_ID, PROJECT_NAME, PROGRAM_NAME, BUSINESS_UNIT, CONTRACT_VALUE,
                  LABOR_TO_DATE, BURN_PCT, SCHEDULE_PCT, BURN_VS_SCHEDULE_GAP, AT_RISK
           FROM WILLDAN_DEMO.ANALYTICS.PROJECT_BURN ORDER BY BURN_VS_SCHEDULE_GAP DESC"""
    )
    for c in ["CONTRACT_VALUE", "LABOR_TO_DATE", "BURN_PCT", "SCHEDULE_PCT", "BURN_VS_SCHEDULE_GAP"]:
        burn[c] = pd.to_numeric(burn[c])

    k1, k2, k3, k4 = st.columns(4)
    k1.metric("Total contract value", f"${burn.CONTRACT_VALUE.sum():,.0f}")
    k2.metric("Labor to date", f"${burn.LABOR_TO_DATE.sum():,.0f}")
    k3.metric("Projects at risk", int(burn.AT_RISK.sum()))
    k4.metric("Avg burn", f"{burn.BURN_PCT.mean():.1f}%")

    left, right = st.columns([3, 2])
    with left:
        st.subheader("Burn vs schedule")
        diag = alt.Chart(pd.DataFrame({"x": [0, 110], "y": [0, 110]})).mark_line(
            strokeDash=[4, 4], color="gray"
        ).encode(x="x", y="y")
        pts = alt.Chart(burn).mark_circle(size=120).encode(
            x=alt.X("SCHEDULE_PCT:Q", title="Schedule %", scale=alt.Scale(domain=[0, 110])),
            y=alt.Y("BURN_PCT:Q", title="Burn %", scale=alt.Scale(domain=[0, 110])),
            color=alt.Color("AT_RISK:N", title="At risk"),
            tooltip=["PROJECT_ID", "PROJECT_NAME", "PROGRAM_NAME", "BURN_PCT", "SCHEDULE_PCT",
                     "BURN_VS_SCHEDULE_GAP", alt.Tooltip("CONTRACT_VALUE:Q", format="$,.0f")],
        )
        st.altair_chart(diag + pts, use_container_width=True)
    with right:
        st.subheader("At-risk projects")
        st.dataframe(
            burn[burn.AT_RISK][["PROJECT_ID", "PROJECT_NAME", "BURN_PCT", "SCHEDULE_PCT", "BURN_VS_SCHEDULE_GAP"]],
            hide_index=True, use_container_width=True,
        )

    st.subheader("Monthly labor cost by business unit")
    labor = q(
        """SELECT PERIOD, BUSINESS_UNIT, SUM(LABOR_COST) AS LABOR_COST
           FROM WILLDAN_DEMO.CURATED.FACT_LABOR GROUP BY 1, 2 ORDER BY 1, 2"""
    )
    labor["LABOR_COST"] = pd.to_numeric(labor["LABOR_COST"])
    st.altair_chart(
        alt.Chart(labor).mark_bar().encode(
            x=alt.X("PERIOD:O", title="Period"),
            y=alt.Y("LABOR_COST:Q", title="Labor cost", stack="zero"),
            color=alt.Color("BUSINESS_UNIT:N", title="Business unit"),
            tooltip=["PERIOD", "BUSINESS_UNIT", alt.Tooltip("LABOR_COST:Q", format="$,.0f")],
        ),
        use_container_width=True,
    )

    st.subheader("Projects")
    st.dataframe(burn, hide_index=True, use_container_width=True)

with tab_feed:
    c1, c2, c3 = st.columns(3)
    feed = c1.selectbox("Feed", list(FEEDS))
    view = FEEDS[feed]
    periods = q(f"SELECT DISTINCT PERIOD FROM {view} ORDER BY PERIOD DESC")["PERIOD"].tolist()
    period = c2.selectbox("Period", periods)
    project = c3.text_input("Project filter (optional, PROJECT_ID)", "").strip() or None

    preview = q(
        f"SELECT * FROM {view} WHERE PERIOD = ? AND (? IS NULL OR PROJECT_ID = ?)",
        params=[period, project, project],
        ttl=0,
    )
    st.caption(f"{len(preview):,} rows")
    st.dataframe(preview, hide_index=True, use_container_width=True)

    b1, b2, b3 = st.columns(3)
    if b1.button("Export to stage", type="primary"):
        res = q("CALL WILLDAN_DEMO.CURATED.SP_EXPORT_FEED(?, ?)", params=[feed, period], ttl=0)
        st.success("Export complete")
        st.write(res.iloc[0, 0])
    if b2.button("Send to API"):
        res = q("CALL WILLDAN_DEMO.APPS.SP_SEND_FEED_TO_API(?, ?, ?)", params=[feed, period, project], ttl=0)
        st.success("API delivery finished")
        st.json(res.iloc[0, 0])
    b3.download_button(
        "Download CSV",
        preview.to_csv(index=False).encode("utf-8"),
        file_name=f"{feed.lower()}_{period}.csv",
        mime="text/csv",
    )

with tab_pipe:
    st.subheader("Export log")
    st.dataframe(
        q("SELECT * FROM WILLDAN_DEMO.CURATED.EXPORT_LOG ORDER BY STARTED_AT DESC", ttl=0),
        hide_index=True, use_container_width=True,
    )
    st.subheader("Loaded files (RAW.LAB_HS_RAW)")
    st.dataframe(
        q(
            """SELECT _SOURCE_FILE AS SOURCE_FILE, COUNT(*) AS ROWS_LOADED, MAX(_LOADED_AT) AS LOADED_AT
               FROM WILLDAN_DEMO.RAW.LAB_HS_RAW GROUP BY 1 ORDER BY SOURCE_FILE DESC""",
            ttl=60,
        ),
        hide_index=True, use_container_width=True,
    )
    st.subheader("Dynamic tables")
    st.dataframe(
        q(
            """SELECT NAME, SCHEMA_NAME, TARGET_LAG_SEC, TARGET_LAG_TYPE,
                      SCHEDULING_STATE:state::string AS SCHEDULING_STATE,
                      LAST_COMPLETED_REFRESH_STATE, LATEST_DATA_TIMESTAMP
               FROM TABLE(WILLDAN_DEMO.INFORMATION_SCHEMA.DYNAMIC_TABLES())
               WHERE DATABASE_NAME = 'WILLDAN_DEMO'
               QUALIFY ROW_NUMBER() OVER (PARTITION BY QUALIFIED_NAME
                                          ORDER BY LATEST_DATA_TIMESTAMP DESC NULLS LAST) = 1
               ORDER BY SCHEMA_NAME, NAME""",
            ttl=0,
        ),
        hide_index=True, use_container_width=True,
    )
