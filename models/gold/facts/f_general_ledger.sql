-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T05:20:08Z.
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

-- FACT_GENERAL_LEDGER | Transaction fact
-- Grain: one row per transaction accounting line (posted GL entry)
-- Source: SILVER.STG_NS_TRANSACTIONACCOUNTINGLINE enriched with TRANSACTIONLINE + TRANSACTION
--
-- MULTI-CURRENCY CONSOLIDATION (added):
--   FUNCTIONAL_NET_AMOUNT = NET_AMOUNT as posted in the subsidiary's functional currency.
--   REPORTING_NET_AMOUNT_USD = FUNCTIONAL_NET_AMOUNT * the correct period rate to USD.
--   Rate type per case rules: AVERAGE for P&L accounts (Income/COGS/Expense),
--   CURRENT for asset/liability accounts, HISTORICAL for equity. Rate comes from
--   CONSOLIDATEDEXCHANGERATE (FROM = subsidiary functional currency, TO = base USD,
--   matched on posting period). USD-functional subsidiaries use rate 1.0.
--   FX_RATE_MATCHED flags lines where a rate (or USD) was found; unmatched foreign
--   lines fall back to 1.0 and should be reviewed (rare / missing rate rows).

WITH tal AS (SELECT * FROM {{ ref('stg_ns_transactionaccountingline') }}),
     tl  AS (SELECT * FROM {{ ref('stg_ns_transactionline') }}),
     txn AS (SELECT * FROM {{ ref('stg_ns_transaction') }}),
     sub AS (
        SELECT ID AS SUBSIDIARY_ID, CURRENCY_ID
        FROM {{ ref('stg_ns_subsidiary') }}
        WHERE IS_ACTIVE = TRUE
     ),
     acct AS (
        SELECT ID AS ACCOUNT_ID, UPPER(TRIM(ACCOUNT_TYPE)) AS ACCT_TYPE
        FROM {{ ref('d_account') }}
        WHERE IS_CURRENT = TRUE
     ),
     usd AS (
        -- NOTE: the CURRENCY source flags SIX currencies as base (AUD, DKK, EUR, USD,
        -- CAD, GBP) -- a source data-quality issue -- so IS_BASE_CURRENCY is unreliable.
        -- Anchor the group reporting currency explicitly on USD by name.
        SELECT ID AS USD_CURRENCY_ID
        FROM {{ ref('d_currency') }}
        WHERE UPPER(TRIM(CURRENCY_NAME)) = 'USD'
        LIMIT 1
     ),
     cer AS (
        -- one rate row per (period, from-currency) to USD; averaged to avoid fan-out
        SELECT
            POSTING_PERIOD_ID,
            FROM_CURRENCY_ID,
            AVG(AVERAGE_RATE)    AS AVERAGE_RATE,
            AVG(CURRENT_RATE)    AS CURRENT_RATE,
            AVG(HISTORICAL_RATE) AS HISTORICAL_RATE
        FROM {{ ref('stg_ns_consolidatedexchangerate') }}
        WHERE IS_ACTIVE = TRUE
          AND TO_CURRENCY_ID = (SELECT USD_CURRENCY_ID FROM usd)
        GROUP BY POSTING_PERIOD_ID, FROM_CURRENCY_ID
     )
SELECT
    tal.SURROGATE_KEY                                                       AS GENERAL_LEDGER_KEY,
    TO_NUMBER(TO_CHAR(txn.TRANSACTION_DATE,'YYYYMMDD'))                      AS POSTING_DATE_KEY,
    MD5(COALESCE(CAST(txn.POSTING_PERIOD_ID AS VARCHAR),'-1'))               AS ACCOUNTING_PERIOD_KEY,
    MD5(COALESCE(CAST(tal.ACCOUNT_ID AS VARCHAR),'-1'))                      AS ACCOUNT_KEY,
    MD5(COALESCE(CAST(tal.TRANSACTION_ID AS VARCHAR),'-1'))                  AS TRANSACTION_KEY,
    MD5(COALESCE(CAST(COALESCE(tl.ENTITY_ID, txn.ENTITY_ID) AS VARCHAR),'-1')) AS ENTITY_KEY,
    MD5(COALESCE(CAST(tl.SUBSIDIARY_ID AS VARCHAR),'-1'))                    AS SUBSIDIARY_KEY,
    MD5(COALESCE(CAST(tl.DEPARTMENT_ID AS VARCHAR),'-1'))                    AS DEPARTMENT_KEY,
    MD5(COALESCE(CAST(tl.CLASS_ID AS VARCHAR),'-1'))                         AS CLASS_KEY,
    MD5(COALESCE(CAST(tl.LOCATION_ID AS VARCHAR),'-1'))                      AS LOCATION_KEY,
    MD5(COALESCE(CAST(tl.ITEM_ID AS VARCHAR),'-1'))                          AS ITEM_KEY,
    MD5(COALESCE(CAST(txn.CURRENCY_ID AS VARCHAR),'-1'))                     AS CURRENCY_KEY,
    txn.DOCUMENT_NUMBER                                                      AS DOCUMENT_NUMBER,
    CAST(tal.TRANSACTION_LINE_ID AS VARCHAR)                                 AS TRANSACTION_LINE_ID,
    CAST(tal.ACCOUNTING_BOOK_ID AS VARCHAR)                                  AS ACCOUNTING_BOOK_ID,
    CAST(tal.AMOUNT AS NUMBER(18,4))                                         AS GL_AMOUNT,
    CAST(tal.DEBIT AS NUMBER(18,4))                                          AS DEBIT_AMOUNT,
    CAST(tal.CREDIT AS NUMBER(18,4))                                         AS CREDIT_AMOUNT,
    CAST(tal.NET_AMOUNT AS NUMBER(18,4))                                     AS NET_AMOUNT,
    CAST(tal.AMOUNT_PAID AS NUMBER(18,4))                                    AS PAID_AMOUNT,
    CAST(tal.AMOUNT_UNPAID AS NUMBER(18,4))                                  AS UNPAID_AMOUNT,
    CAST(tal.EXCHANGE_RATE AS NUMBER(10,6))                                  AS EXCHANGE_RATE,
    tal.IS_POSTING                                                          AS IS_POSTING,
    -- ---------- multi-currency consolidation ----------
    sub.CURRENCY_ID                                                         AS FUNCTIONAL_CURRENCY_ID,
    CAST(tal.NET_AMOUNT AS NUMBER(18,4))                                     AS FUNCTIONAL_NET_AMOUNT,
    CASE
        WHEN acct.ACCT_TYPE IN ('INCOME','OTHINCOME','OTHER INCOME','REVENUE',
                                'COGS','COST OF GOODS SOLD','COSTOFGOODSSOLD',
                                'EXPENSE','OTHEXPENSE','OTHER EXPENSE') THEN 'AVERAGE'
        WHEN acct.ACCT_TYPE = 'EQUITY'                                  THEN 'HISTORICAL'
        ELSE 'CURRENT'
    END                                                                     AS FX_RATE_TYPE,
    CAST(
        CASE
            WHEN sub.CURRENCY_ID = (SELECT USD_CURRENCY_ID FROM usd) THEN 1.0
            WHEN acct.ACCT_TYPE IN ('INCOME','OTHINCOME','OTHER INCOME','REVENUE',
                                    'COGS','COST OF GOODS SOLD','COSTOFGOODSSOLD',
                                    'EXPENSE','OTHEXPENSE','OTHER EXPENSE') THEN cer.AVERAGE_RATE
            WHEN acct.ACCT_TYPE = 'EQUITY'                                  THEN cer.HISTORICAL_RATE
            ELSE cer.CURRENT_RATE
        END AS NUMBER(18,6))                                                AS FX_RATE_APPLIED,
    CASE WHEN sub.CURRENCY_ID = (SELECT USD_CURRENCY_ID FROM usd)
              OR cer.FROM_CURRENCY_ID IS NOT NULL THEN TRUE ELSE FALSE END   AS FX_RATE_MATCHED,
    CAST(tal.NET_AMOUNT * COALESCE(
        CASE
            WHEN sub.CURRENCY_ID = (SELECT USD_CURRENCY_ID FROM usd) THEN 1.0
            WHEN acct.ACCT_TYPE IN ('INCOME','OTHINCOME','OTHER INCOME','REVENUE',
                                    'COGS','COST OF GOODS SOLD','COSTOFGOODSSOLD',
                                    'EXPENSE','OTHEXPENSE','OTHER EXPENSE') THEN cer.AVERAGE_RATE
            WHEN acct.ACCT_TYPE = 'EQUITY'                                  THEN cer.HISTORICAL_RATE
            ELSE cer.CURRENT_RATE
        END, 1.0) AS NUMBER(18,4))                                          AS REPORTING_NET_AMOUNT_USD,
    -- --------------------------------------------------
    SYSDATE()                                                              AS DW_CREATED_AT,
    SYSDATE()                                                              AS DW_UPDATED_AT,
    'NETSUITE'                                                             AS DW_SOURCE_SYSTEM,
    CAST(NULL AS VARCHAR)                                                  AS DW_BATCH_ID
FROM tal
LEFT JOIN tl  ON tal.TRANSACTION_ID = tl.TRANSACTION_ID AND tal.TRANSACTION_LINE_ID = tl.LINE_ID
LEFT JOIN txn ON tal.TRANSACTION_ID = txn.ID
LEFT JOIN sub ON tl.SUBSIDIARY_ID = sub.SUBSIDIARY_ID
LEFT JOIN acct ON tal.ACCOUNT_ID = acct.ACCOUNT_ID
LEFT JOIN cer ON cer.POSTING_PERIOD_ID = txn.POSTING_PERIOD_ID
             AND cer.FROM_CURRENCY_ID  = sub.CURRENCY_ID
