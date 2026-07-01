-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T04:51:55Z.
-- The content has been verified by the designated engineer.
-- ============================================================

{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold','fact'],
    on_schema_change = 'fail'
  )
}}

-- FACT_BALANCE_SHEET | Periodic snapshot fact
-- Grain: one row per account per subsidiary per accounting period (period-end balance)
-- Source: DERIVED from FACT_GENERAL_LEDGER + DIM_ACCOUNTING_PERIOD

WITH gl AS (
    SELECT ACCOUNT_KEY, SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY, CURRENCY_KEY,
           DEBIT_AMOUNT, CREDIT_AMOUNT, NET_AMOUNT
    FROM {{ ref('f_general_ledger') }}
),
per AS (
    SELECT ACCOUNTING_PERIOD_KEY, PERIOD_END_DATE
    FROM {{ ref('d_accounting_period') }}
),
agg AS (
    SELECT
        ACCOUNT_KEY, SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY,
        MAX(CURRENCY_KEY)                    AS CURRENCY_KEY,
        SUM(DEBIT_AMOUNT)                    AS PERIOD_DEBIT_AMOUNT,
        SUM(CREDIT_AMOUNT)                   AS PERIOD_CREDIT_AMOUNT,
        SUM(NET_AMOUNT)                      AS PERIOD_NET_AMOUNT
    FROM gl
    GROUP BY ACCOUNT_KEY, SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY
),
joined AS (
    SELECT agg.*, per.PERIOD_END_DATE
    FROM agg LEFT JOIN per ON agg.ACCOUNTING_PERIOD_KEY = per.ACCOUNTING_PERIOD_KEY
)
SELECT
    MD5(CONCAT_WS('|', ACCOUNT_KEY, SUBSIDIARY_KEY, ACCOUNTING_PERIOD_KEY)) AS BALANCE_SHEET_KEY,
    TO_NUMBER(TO_CHAR(PERIOD_END_DATE,'YYYYMMDD'))                          AS PERIOD_END_DATE_KEY,
    ACCOUNTING_PERIOD_KEY,
    ACCOUNT_KEY,
    SUBSIDIARY_KEY,
    CURRENCY_KEY,
    CAST(PERIOD_DEBIT_AMOUNT  AS NUMBER(18,4))                             AS PERIOD_DEBIT_AMOUNT,
    CAST(PERIOD_CREDIT_AMOUNT AS NUMBER(18,4))                             AS PERIOD_CREDIT_AMOUNT,
    CAST(PERIOD_NET_AMOUNT    AS NUMBER(18,4))                             AS PERIOD_NET_AMOUNT,
    CAST(SUM(PERIOD_NET_AMOUNT) OVER (
        PARTITION BY ACCOUNT_KEY, SUBSIDIARY_KEY
        ORDER BY PERIOD_END_DATE
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NUMBER(18,4))  AS ENDING_BALANCE_AMOUNT,
    SYSDATE()                                                              AS DW_CREATED_AT,
    SYSDATE()                                                              AS DW_UPDATED_AT,
    'NETSUITE'                                                             AS DW_SOURCE_SYSTEM,
    CAST(NULL AS VARCHAR)                                                  AS DW_BATCH_ID
FROM joined
