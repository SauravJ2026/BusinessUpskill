-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T04:51:55Z.
-- The content has been verified by the designated engineer.
-- ============================================================

{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold','dimension','scd1'],
    on_schema_change = 'fail'
  )
}}

-- DIM_TRANSACTION_STATUS | SCD1 | source: SILVER.STG_NS_TRANSACTIONSTATUS | Grain: One row per transaction-type / status combination
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_transactionstatus') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(CONCAT_WS('|', COALESCE(CAST(TRANSACTION_TYPE AS VARCHAR),'-1'), COALESCE(CAST(TRANSACTION_STATUS_ID AS VARCHAR),'-1'))) AS TRANSACTION_STATUS_KEY,
        TRANSACTION_TYPE                                     AS TRANSACTION_TYPE,
        TRANSACTION_STATUS_ID                                AS TRANSACTION_STATUS_ID,
        TRANSACTION_STATUS_NAME                              AS STATUS_NAME,
        TRANSACTION_STATUS_FULL_NAME                         AS STATUS_FULL_NAME,
        TRAN_CUSTOM_TYPE_ID                                  AS TRAN_CUSTOM_TYPE_ID,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
