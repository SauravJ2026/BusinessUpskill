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

-- DIM_EMPLOYEE | SCD2 | source: SILVER.STG_NS_EMPLOYEE | Grain: One row per employee version
WITH src AS (
    SELECT * FROM {{ ref('stg_ns_employee') }}
    WHERE IS_ACTIVE = TRUE
)
SELECT
        MD5(COALESCE(CAST(ID AS VARCHAR),'-1'))              AS EMPLOYEE_KEY,
        ID                                                   AS ID,
        FIRST_NAME                                           AS FIRST_NAME,
        LAST_NAME                                            AS LAST_NAME,
        TITLE                                                AS JOB_TITLE,
        EMAIL                                                AS EMAIL,
        PHONE                                                AS PHONE,
        MOBILE_PHONE                                         AS MOBILE_PHONE,
        GENDER                                               AS GENDER,
        BIRTH_DATE                                           AS BIRTH_DATE,
        HIRE_DATE                                            AS HIRE_DATE,
        EMPLOYEE_STATUS_ID                                   AS EMPLOYEE_STATUS_ID,
        EMPLOYEE_TYPE_ID                                     AS EMPLOYEE_TYPE_ID,
        DEPARTMENT_ID                                        AS DEPARTMENT_ID,
        CLASS_ID                                             AS CLASS_ID,
        LOCATION_ID                                          AS LOCATION_ID,
        SUBSIDIARY_ID                                        AS SUBSIDIARY_ID,
        SUPERVISOR_ID                                        AS SUPERVISOR_ID,
        IS_SALES_REP                                         AS IS_SALES_REP,
        IS_INACTIVE                                          AS IS_INACTIVE,
        CAST(CURRENT_DATE AS DATE)                   AS EFF_START_DATE,
        CAST(NULL AS DATE)                           AS EFF_END_DATE,
        TRUE                                         AS IS_CURRENT,
        MD5(CONCAT_WS('|', COALESCE(CAST(FIRST_NAME AS VARCHAR),''), COALESCE(CAST(LAST_NAME AS VARCHAR),''), COALESCE(CAST(TITLE AS VARCHAR),''), COALESCE(CAST(EMAIL AS VARCHAR),''), COALESCE(CAST(PHONE AS VARCHAR),''), COALESCE(CAST(MOBILE_PHONE AS VARCHAR),''), COALESCE(CAST(GENDER AS VARCHAR),''), COALESCE(CAST(BIRTH_DATE AS VARCHAR),''), COALESCE(CAST(HIRE_DATE AS VARCHAR),''), COALESCE(CAST(EMPLOYEE_STATUS_ID AS VARCHAR),''), COALESCE(CAST(EMPLOYEE_TYPE_ID AS VARCHAR),''), COALESCE(CAST(DEPARTMENT_ID AS VARCHAR),''), COALESCE(CAST(CLASS_ID AS VARCHAR),''), COALESCE(CAST(LOCATION_ID AS VARCHAR),''), COALESCE(CAST(SUBSIDIARY_ID AS VARCHAR),''), COALESCE(CAST(SUPERVISOR_ID AS VARCHAR),''), COALESCE(CAST(IS_SALES_REP AS VARCHAR),''), COALESCE(CAST(IS_INACTIVE AS VARCHAR),''))) AS RECORD_HASH,
        SYSDATE()                                  AS DW_CREATED_AT,
        SYSDATE()                                  AS DW_UPDATED_AT,
        'NETSUITE'                                 AS DW_SOURCE_SYSTEM,
        CAST(NULL AS VARCHAR)                      AS DW_BATCH_ID
FROM src
