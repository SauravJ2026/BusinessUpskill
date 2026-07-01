-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T04:51:55Z.
-- The content has been verified by the designated engineer.
-- ============================================================

{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold','dimension','scd2'],
    on_schema_change = 'fail'
  )
}}

-- DIM_SUBSIDIARY | SCD2 | source: SILVER.STG_NS_SUBSIDIARY | Grain: One row per subsidiary version
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_subsidiary') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS SUBSIDIARY_KEY,
        ID                                                   AS ID,
        NAME                                                 AS SUBSIDIARY_NAME,
        FULL_NAME                                            AS FULL_NAME,
        LEGAL_NAME                                           AS LEGAL_NAME,
        COUNTRY                                              AS COUNTRY,
        STATE                                                AS STATE,
        CURRENCY_ID                                          AS CURRENCY_ID,
        PARENT_ID                                            AS PARENT_SUBSIDIARY_ID,
        IS_ELIMINATION                                       AS IS_ELIMINATION,
        IS_INACTIVE                                          AS IS_INACTIVE,
        CAST(CURRENT_DATE AS DATE)                   AS EFF_START_DATE,
        CAST(NULL AS DATE)                           AS EFF_END_DATE,
        TRUE                                         AS IS_CURRENT,
        MD5(CONCAT_WS('|', COALESCE(CAST(NAME AS VARCHAR),''), COALESCE(CAST(FULL_NAME AS VARCHAR),''), COALESCE(CAST(LEGAL_NAME AS VARCHAR),''), COALESCE(CAST(COUNTRY AS VARCHAR),''), COALESCE(CAST(STATE AS VARCHAR),''), COALESCE(CAST(CURRENCY_ID AS VARCHAR),''), COALESCE(CAST(PARENT_ID AS VARCHAR),''), COALESCE(CAST(IS_ELIMINATION AS VARCHAR),''), COALESCE(CAST(IS_INACTIVE AS VARCHAR),''))) AS RECORD_HASH,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
