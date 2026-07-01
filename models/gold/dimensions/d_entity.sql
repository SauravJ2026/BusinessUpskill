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

-- DIM_ENTITY | SCD2 | source: SILVER.STG_NS_ENTITY | Grain: One row per entity version
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_entity') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS ENTITY_KEY,
        ID                                                   AS ID,
        ENTITY_ID_CODE                                       AS ENTITY_CODE,
        FULL_NAME                                            AS ENTITY_NAME,
        ENTITY_TITLE                                         AS ENTITY_TITLE,
        ENTITY_TYPE                                          AS ENTITY_TYPE,
        CUSTOMER_TYPE                                        AS CUSTOMER_TYPE,
        CUSTOMER_STATUS                                      AS CUSTOMER_STATUS,
        EMAIL                                                AS EMAIL,
        PHONE                                                AS PHONE,
        CREDIT_LIMIT                                         AS CREDIT_LIMIT,
        IS_PERSON                                            AS IS_PERSON,
        IS_INACTIVE                                          AS IS_INACTIVE,
        PARENT_ID                                            AS PARENT_ENTITY_ID,
        TOP_LEVEL_PARENT_ID                                  AS TOP_LEVEL_PARENT_ID,
        CUSTOMER_ID                                          AS CUSTOMER_ID,
        VENDOR_ID                                            AS VENDOR_ID,
        EMPLOYEE_ID                                          AS EMPLOYEE_ID,
        PARTNER_ID                                           AS PARTNER_ID,
        DATE_CREATED_TS_UTC                                  AS DATE_CREATED_TS_UTC,
        CAST(CURRENT_DATE AS DATE)                   AS EFF_START_DATE,
        CAST(NULL AS DATE)                           AS EFF_END_DATE,
        TRUE                                         AS IS_CURRENT,
        MD5(CONCAT_WS('|', COALESCE(CAST(ENTITY_ID_CODE AS VARCHAR),''), COALESCE(CAST(FULL_NAME AS VARCHAR),''), COALESCE(CAST(ENTITY_TITLE AS VARCHAR),''), COALESCE(CAST(ENTITY_TYPE AS VARCHAR),''), COALESCE(CAST(CUSTOMER_TYPE AS VARCHAR),''), COALESCE(CAST(CUSTOMER_STATUS AS VARCHAR),''), COALESCE(CAST(EMAIL AS VARCHAR),''), COALESCE(CAST(PHONE AS VARCHAR),''), COALESCE(CAST(CREDIT_LIMIT AS VARCHAR),''), COALESCE(CAST(IS_PERSON AS VARCHAR),''), COALESCE(CAST(IS_INACTIVE AS VARCHAR),''), COALESCE(CAST(PARENT_ID AS VARCHAR),''), COALESCE(CAST(TOP_LEVEL_PARENT_ID AS VARCHAR),''), COALESCE(CAST(CUSTOMER_ID AS VARCHAR),''), COALESCE(CAST(VENDOR_ID AS VARCHAR),''), COALESCE(CAST(EMPLOYEE_ID AS VARCHAR),''), COALESCE(CAST(PARTNER_ID AS VARCHAR),''), COALESCE(CAST(DATE_CREATED_TS_UTC AS VARCHAR),''))) AS RECORD_HASH,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
