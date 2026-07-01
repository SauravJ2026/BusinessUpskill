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

-- DIM_ACCOUNT | SCD2 | source: SILVER.STG_NS_ACCOUNT | Grain: One row per account version
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_account') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS ACCOUNT_KEY,
        ID                                                   AS ID,
        ACCOUNT_NUMBER                                       AS ACCOUNT_NUMBER,
        ACCOUNT_SEARCH_DISPLAY_NAME                          AS ACCOUNT_NAME,
        FULL_NAME                                            AS FULL_NAME,
        ACCOUNT_TYPE                                         AS ACCOUNT_TYPE,
        SPECIAL_ACCOUNT_TYPE                                 AS SPECIAL_ACCOUNT_TYPE,
        DESCRIPTION                                          AS ACCOUNT_DESCRIPTION,
        DISPLAY_NAME_WITH_HIERARCHY                          AS HIERARCHY_NAME,
        PARENT_ID                                            AS PARENT_ACCOUNT_ID,
        CASH_FLOW_RATE                                       AS CASH_FLOW_RATE,
        CLASS_ID                                             AS CLASS_ID,
        CURRENCY_ID                                          AS CURRENCY_ID,
        SUBSIDIARY                                           AS SUBSIDIARY,
        DEPARTMENT                                           AS DEPARTMENT,
        LOCATION_ID                                          AS LOCATION_ID,
        IS_SUMMARY                                           AS IS_SUMMARY,
        ELIMINATE                                            AS IS_ELIMINATE,
        IS_INACTIVE                                          AS IS_INACTIVE,
        CAST(CURRENT_DATE AS DATE)                   AS EFF_START_DATE,
        CAST(NULL AS DATE)                           AS EFF_END_DATE,
        TRUE                                         AS IS_CURRENT,
        MD5(CONCAT_WS('|', COALESCE(CAST(ACCOUNT_NUMBER AS VARCHAR),''), COALESCE(CAST(ACCOUNT_SEARCH_DISPLAY_NAME AS VARCHAR),''), COALESCE(CAST(FULL_NAME AS VARCHAR),''), COALESCE(CAST(ACCOUNT_TYPE AS VARCHAR),''), COALESCE(CAST(SPECIAL_ACCOUNT_TYPE AS VARCHAR),''), COALESCE(CAST(DESCRIPTION AS VARCHAR),''), COALESCE(CAST(DISPLAY_NAME_WITH_HIERARCHY AS VARCHAR),''), COALESCE(CAST(PARENT_ID AS VARCHAR),''), COALESCE(CAST(CASH_FLOW_RATE AS VARCHAR),''), COALESCE(CAST(CLASS_ID AS VARCHAR),''), COALESCE(CAST(CURRENCY_ID AS VARCHAR),''), COALESCE(CAST(SUBSIDIARY AS VARCHAR),''), COALESCE(CAST(DEPARTMENT AS VARCHAR),''), COALESCE(CAST(LOCATION_ID AS VARCHAR),''), COALESCE(CAST(IS_SUMMARY AS VARCHAR),''), COALESCE(CAST(ELIMINATE AS VARCHAR),''), COALESCE(CAST(IS_INACTIVE AS VARCHAR),''))) AS RECORD_HASH,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
