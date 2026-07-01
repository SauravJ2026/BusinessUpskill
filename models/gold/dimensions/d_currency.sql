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

-- DIM_CURRENCY | SCD1 | source: SILVER.STG_NS_CURRENCY | Grain: One row per currency
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_currency') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS CURRENCY_KEY,
        ID                                                   AS ID,
        NAME                                                 AS CURRENCY_NAME,
        SYMBOL                                               AS CURRENCY_SYMBOL,
        EXCHANGE_RATE                                        AS EXCHANGE_RATE,
        IS_BASE_CURRENCY                                     AS IS_BASE_CURRENCY,
        IS_INACTIVE                                          AS IS_INACTIVE,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
