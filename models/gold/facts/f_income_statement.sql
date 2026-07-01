-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T05:20:08Z.
-- The content has been verified by the designated engineer.
-- ============================================================
--
-- FACT_INCOME_STATEMENT | Derived P&L fact
-- Grain: one row per SUBSIDIARY x ACCOUNTING_PERIOD x DEPARTMENT x CLASS.
-- Source: F_GENERAL_LEDGER filtered to P&L account types.
-- Measures come in two currencies:
--   *_ (functional): NET_AMOUNT as posted in the subsidiary currency.
--   *_USD: REPORTING_NET_AMOUNT_USD, already translated at AVERAGE rate in the GL
--          fact (P&L accounts use the average period rate per case rules).
-- Income accounts carry credit balances (negative net) -> negated for positive revenue.
-- EBITDA / NET_INCOME are simplified (gross_profit - opex).
-- ============================================================

{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold','fact'],
    on_schema_change = 'fail'
  )
}}

WITH gl AS (
    SELECT
        SUBSIDIARY_KEY,
        ACCOUNTING_PERIOD_KEY,
        DEPARTMENT_KEY,
        CLASS_KEY,
        ACCOUNT_KEY,
        NET_AMOUNT,
        REPORTING_NET_AMOUNT_USD
    FROM {{ ref('f_general_ledger') }}
),
acct AS (
    SELECT ACCOUNT_KEY, UPPER(TRIM(ACCOUNT_TYPE)) AS ACCT_TYPE
    FROM {{ ref('d_account') }}
    WHERE IS_CURRENT = TRUE
),
joined AS (
    SELECT
        gl.SUBSIDIARY_KEY,
        gl.ACCOUNTING_PERIOD_KEY,
        gl.DEPARTMENT_KEY,
        gl.CLASS_KEY,
        gl.NET_AMOUNT,
        gl.REPORTING_NET_AMOUNT_USD,
        CASE
            WHEN acct.ACCT_TYPE IN ('INCOME','OTHINCOME','OTHER INCOME','REVENUE')            THEN 'REVENUE'
            WHEN acct.ACCT_TYPE IN ('COGS','COST OF GOODS SOLD','COSTOFGOODSSOLD')            THEN 'COGS'
            WHEN acct.ACCT_TYPE IN ('EXPENSE','OTHEXPENSE','OTHER EXPENSE','OPERATING EXPENSE') THEN 'OPEX'
            ELSE 'NON_PL'
        END AS PL_BUCKET
    FROM gl
    JOIN acct ON gl.ACCOUNT_KEY = acct.ACCOUNT_KEY
),
agg AS (
    SELECT
        SUBSIDIARY_KEY,
        ACCOUNTING_PERIOD_KEY,
        DEPARTMENT_KEY,
        CLASS_KEY,
        SUM(CASE WHEN PL_BUCKET = 'REVENUE' THEN -NET_AMOUNT ELSE 0 END)               AS REVENUE,
        SUM(CASE WHEN PL_BUCKET = 'COGS'    THEN  NET_AMOUNT ELSE 0 END)               AS COGS,
        SUM(CASE WHEN PL_BUCKET = 'OPEX'    THEN  NET_AMOUNT ELSE 0 END)               AS OPERATING_EXPENSE,
        SUM(CASE WHEN PL_BUCKET = 'REVENUE' THEN -REPORTING_NET_AMOUNT_USD ELSE 0 END) AS REVENUE_USD,
        SUM(CASE WHEN PL_BUCKET = 'COGS'    THEN  REPORTING_NET_AMOUNT_USD ELSE 0 END) AS COGS_USD,
        SUM(CASE WHEN PL_BUCKET = 'OPEX'    THEN  REPORTING_NET_AMOUNT_USD ELSE 0 END) AS OPERATING_EXPENSE_USD
    FROM joined
    WHERE PL_BUCKET <> 'NON_PL'
    GROUP BY SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY, DEPARTMENT_KEY, CLASS_KEY
)
SELECT
    MD5(CONCAT_WS('|', SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY, DEPARTMENT_KEY, CLASS_KEY)) AS INCOME_STATEMENT_KEY,
    SUBSIDIARY_KEY,
    ACCOUNTING_PERIOD_KEY,
    DEPARTMENT_KEY,
    CLASS_KEY,
    -- functional currency
    CAST(REVENUE           AS NUMBER(18,4)) AS REVENUE,
    CAST(COGS              AS NUMBER(18,4)) AS COGS,
    CAST(REVENUE - COGS    AS NUMBER(18,4)) AS GROSS_PROFIT,
    CAST(CASE WHEN REVENUE = 0 THEN NULL ELSE (REVENUE - COGS) / REVENUE END AS NUMBER(18,6)) AS GROSS_MARGIN_PCT,
    CAST(OPERATING_EXPENSE AS NUMBER(18,4)) AS OPERATING_EXPENSE,
    CAST(REVENUE - COGS - OPERATING_EXPENSE AS NUMBER(18,4)) AS EBITDA,
    CAST(REVENUE - COGS - OPERATING_EXPENSE AS NUMBER(18,4)) AS NET_INCOME,
    -- USD consolidated
    CAST(REVENUE_USD           AS NUMBER(18,4)) AS REVENUE_USD,
    CAST(COGS_USD              AS NUMBER(18,4)) AS COGS_USD,
    CAST(REVENUE_USD - COGS_USD AS NUMBER(18,4)) AS GROSS_PROFIT_USD,
    CAST(CASE WHEN REVENUE_USD = 0 THEN NULL ELSE (REVENUE_USD - COGS_USD) / REVENUE_USD END AS NUMBER(18,6)) AS GROSS_MARGIN_PCT_USD,
    CAST(OPERATING_EXPENSE_USD AS NUMBER(18,4)) AS OPERATING_EXPENSE_USD,
    CAST(REVENUE_USD - COGS_USD - OPERATING_EXPENSE_USD AS NUMBER(18,4)) AS EBITDA_USD,
    CAST(REVENUE_USD - COGS_USD - OPERATING_EXPENSE_USD AS NUMBER(18,4)) AS NET_INCOME_USD,
    SYSDATE()             AS DW_CREATED_AT,
    SYSDATE()             AS DW_UPDATED_AT,
    'NETSUITE'            AS DW_SOURCE_SYSTEM,
    CAST(NULL AS VARCHAR) AS DW_BATCH_ID
FROM agg
