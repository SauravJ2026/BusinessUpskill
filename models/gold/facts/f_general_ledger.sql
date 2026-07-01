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

-- FACT_GENERAL_LEDGER | Transaction fact
-- Grain: one row per transaction accounting line (posted GL entry)
-- Source: SILVER.STG_NS_TRANSACTIONACCOUNTINGLINE enriched with TRANSACTIONLINE + TRANSACTION

WITH tal AS (SELECT * FROM {{ ref('stg_ns_transactionaccountingline') }}),
     tl  AS (SELECT * FROM {{ ref('stg_ns_transactionline') }}),
     txn AS (SELECT * FROM {{ ref('stg_ns_transaction') }})
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
    SYSDATE()                                                              AS DW_CREATED_AT,
    SYSDATE()                                                              AS DW_UPDATED_AT,
    'NETSUITE'                                                             AS DW_SOURCE_SYSTEM,
    CAST(NULL AS VARCHAR)                                                  AS DW_BATCH_ID
FROM tal
LEFT JOIN tl  ON tal.TRANSACTION_ID = tl.TRANSACTION_ID AND tal.TRANSACTION_LINE_ID = tl.LINE_ID
LEFT JOIN txn ON tal.TRANSACTION_ID = txn.ID
