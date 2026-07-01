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

-- DIM_ACCOUNTING_PERIOD | SCD1 | source: SILVER.STG_NS_ACCOUNTINGPERIOD | Grain: One row per accounting period
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_accountingperiod') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS ACCOUNTING_PERIOD_KEY,
        ID                                                   AS ID,
        PERIOD_NAME                                          AS PERIOD_NAME,
        START_DATE                                           AS PERIOD_START_DATE,
        END_DATE                                             AS PERIOD_END_DATE,
        IS_QUARTER                                           AS IS_QUARTER,
        IS_YEAR                                              AS IS_YEAR,
        IS_ADJUST                                            AS IS_ADJUSTMENT,
        IS_POSTING                                           AS IS_POSTING,
        IS_CLOSED                                            AS IS_CLOSED,
        IS_ALL_LOCKED                                        AS IS_ALL_LOCKED,
        IS_INACTIVE                                          AS IS_INACTIVE,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
