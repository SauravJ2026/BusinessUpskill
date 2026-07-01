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

-- DIM_ITEM | SCD2 | source: SILVER.STG_NS_ITEM | Grain: One row per item version
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_item') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS ITEM_KEY,
        ID                                                   AS ID,
        ITEM_CODE                                            AS ITEM_CODE,
        DISPLAY_NAME                                         AS ITEM_NAME,
        FULL_NAME                                            AS FULL_NAME,
        ITEM_TYPE                                            AS ITEM_TYPE,
        SUBTYPE                                              AS ITEM_SUBTYPE,
        CLASS_ID                                             AS CLASS_ID,
        DEPARTMENT_ID                                        AS DEPARTMENT_ID,
        INCOME_ACCOUNT                                       AS INCOME_ACCOUNT,
        EXPENSE_ACCOUNT                                      AS EXPENSE_ACCOUNT,
        DEFERRED_REVENUE_ACCOUNT_ID                          AS DEFERRED_REVENUE_ACCOUNT_ID,
        ASSET_ACCOUNT_ID                                     AS ASSET_ACCOUNT_ID,
        LOCATION                                             AS LOCATION,
        SUBSIDIARY                                           AS SUBSIDIARY,
        IS_INACTIVE                                          AS IS_INACTIVE,
        CAST(CURRENT_DATE AS DATE)                   AS EFF_START_DATE,
        CAST(NULL AS DATE)                           AS EFF_END_DATE,
        TRUE                                         AS IS_CURRENT,
        MD5(CONCAT_WS('|', COALESCE(CAST(ITEM_CODE AS VARCHAR),''), COALESCE(CAST(DISPLAY_NAME AS VARCHAR),''), COALESCE(CAST(FULL_NAME AS VARCHAR),''), COALESCE(CAST(ITEM_TYPE AS VARCHAR),''), COALESCE(CAST(SUBTYPE AS VARCHAR),''), COALESCE(CAST(CLASS_ID AS VARCHAR),''), COALESCE(CAST(DEPARTMENT_ID AS VARCHAR),''), COALESCE(CAST(INCOME_ACCOUNT AS VARCHAR),''), COALESCE(CAST(EXPENSE_ACCOUNT AS VARCHAR),''), COALESCE(CAST(DEFERRED_REVENUE_ACCOUNT_ID AS VARCHAR),''), COALESCE(CAST(ASSET_ACCOUNT_ID AS VARCHAR),''), COALESCE(CAST(LOCATION AS VARCHAR),''), COALESCE(CAST(SUBSIDIARY AS VARCHAR),''), COALESCE(CAST(IS_INACTIVE AS VARCHAR),''))) AS RECORD_HASH,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
