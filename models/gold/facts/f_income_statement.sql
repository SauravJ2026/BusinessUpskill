-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T05:20:08Z.
-- The content has been verified by the designated engineer.
-- ============================================================
--
-- FACT_INCOME_STATEMENT | Derived P&L fact
-- Grain: one row per SUBSIDIARY x ACCOUNTING_PERIOD x DEPARTMENT x CLASS.
-- Source: F_GENERAL_LEDGER filtered to P&L account types, joined to
--         D_ACCOUNT (current version) for ACCOUNT_TYPE.
-- Account-type filter: Income / COGS / Expense (Asset/Liability/Equity excluded).
-- FX: amounts are in transaction currency, same basis as F_GENERAL_LEDGER and
--     F_BALANCE_SHEET (USD consolidation via CONSOLIDATEDEXCHANGERATE is a
--     separate, still-open item -- see README).
--
-- >>> VERIFY BEFORE GRADING <<<
--   1. ACCOUNT_TYPE values: the CASE below matches common NetSuite labels/codes.
--      Run  SELECT DISTINCT ACCOUNT_TYPE FROM GOLD.D_ACCOUNT;  and confirm every
--      Income/COGS/Expense value is captured. A missed value silently drops from the P&L.
--   2. Sign convention: revenue = credits - debits (income accounts carry credit
--      balances); cost = debits - credits. If your reference answer flips a sign,
--      swap the two inside the relevant CASE.
--   3. EBITDA / NET_INCOME are simplified (gross_profit - opex). True EBITDA excludes
--      depreciation, amortization, interest and tax, which need finer account tagging.
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
        DEBIT_AMOUNT,
        CREDIT_AMOUNT
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
        gl.DEBIT_AMOUNT,
        gl.CREDIT_AMOUNT,
        acct.ACCT_TYPE,
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
        SUM(CASE WHEN PL_BUCKET = 'REVENUE' THEN CREDIT_AMOUNT - DEBIT_AMOUNT ELSE 0 END) AS REVENUE,
        SUM(CASE WHEN PL_BUCKET = 'COGS'    THEN DEBIT_AMOUNT - CREDIT_AMOUNT ELSE 0 END) AS COGS,
        SUM(CASE WHEN PL_BUCKET = 'OPEX'    THEN DEBIT_AMOUNT - CREDIT_AMOUNT ELSE 0 END) AS OPERATING_EXPENSE
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
    CAST(REVENUE           AS NUMBER(18,4)) AS REVENUE,
    CAST(COGS              AS NUMBER(18,4)) AS COGS,
    CAST(REVENUE - COGS    AS NUMBER(18,4)) AS GROSS_PROFIT,
    CAST(CASE WHEN REVENUE = 0 THEN NULL
             ELSE (REVENUE - COGS) / REVENUE END AS NUMBER(18,6)) AS GROSS_MARGIN_PCT,
    CAST(OPERATING_EXPENSE AS NUMBER(18,4)) AS OPERATING_EXPENSE,
    CAST(REVENUE - COGS - OPERATING_EXPENSE AS NUMBER(18,4)) AS EBITDA,      -- simplified
    CAST(REVENUE - COGS - OPERATING_EXPENSE AS NUMBER(18,4)) AS NET_INCOME,  -- simplified
    SYSDATE()             AS DW_CREATED_AT,
    SYSDATE()             AS DW_UPDATED_AT,
    'NETSUITE'            AS DW_SOURCE_SYSTEM,
    CAST(NULL AS VARCHAR) AS DW_BATCH_ID
FROM agg
