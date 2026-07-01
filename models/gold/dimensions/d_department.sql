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

-- DIM_DEPARTMENT | SCD1 | source: SILVER.STG_NS_DEPARTMENT | Grain: One row per department
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_department') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS DEPARTMENT_KEY,
        ID                                                   AS ID,
        NAME                                                 AS DEPARTMENT_NAME,
        FULL_NAME                                            AS FULL_NAME,
        PARENT                                               AS PARENT_DEPARTMENT,
        SUBSIDIARY                                           AS SUBSIDIARY,
        IS_INACTIVE                                          AS IS_INACTIVE,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
