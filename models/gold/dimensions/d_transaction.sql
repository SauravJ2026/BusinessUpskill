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

-- DIM_TRANSACTION | SCD1 | source: SILVER.STG_NS_TRANSACTION | Grain: One row per transaction header
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_transaction') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS TRANSACTION_KEY,
        ID                                                   AS ID,
        TRANSACTION_TYPE                                     AS TRANSACTION_TYPE,
        RECORD_TYPE                                          AS RECORD_TYPE,
        ABBREV_TYPE                                          AS ABBREV_TYPE,
        DOCUMENT_NUMBER                                      AS DOCUMENT_NUMBER,
        TRANSACTION_NUMBER                                   AS TRANSACTION_NUMBER,
        TRANSACTION_DISPLAY_NAME                             AS TRANSACTION_DISPLAY_NAME,
        MEMO                                                 AS MEMO,
        STATUS_CODE                                          AS STATUS_CODE,
        APPROVAL_STATUS_ID                                   AS APPROVAL_STATUS_ID,
        IS_POSTING                                           AS IS_POSTING,
        IS_REVERSAL                                          AS IS_REVERSAL,
        IS_VOIDED                                            AS IS_VOIDED,
        INTERCO_TRANSACTION_ID                               AS INTERCO_TRANSACTION_ID,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
