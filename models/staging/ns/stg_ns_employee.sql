-- ============================================================
-- The output have been generated with the assistance of Claude at 2026-06-30T20:04:50Z UTC.
-- The content has been verified by the designated engineer.
-- ============================================================

{{
  config(
    materialized         = 'incremental',
    unique_key           = 'SURROGATE_KEY',
    incremental_strategy = 'merge',
    on_schema_change     = 'fail',
    tags                 = ['silver','staging','ns']
  )
}}

{#
  Model    : stg_ns_employee
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per EMPLOYEE
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'EMPLOYEE') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'EMPLOYEE') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        CAST(BIRTHDATE AS DATE)                                                    AS BIRTH_DATE,
        CAST(CLASS AS NUMBER(38,0))                                                AS CLASS_ID,
        CAST(DEPARTMENT AS NUMBER(38,0))                                           AS DEPARTMENT_ID,
        NULLIF(TRIM(EMAIL),'')                                                     AS EMAIL,
        CAST(EMPLOYEESTATUS AS NUMBER(38,0))                                       AS EMPLOYEE_STATUS_ID,
        CAST(EMPLOYEETYPE AS NUMBER(38,0))                                         AS EMPLOYEE_TYPE_ID,
        NULLIF(TRIM(ENTITYID),'')                                                  AS ENTITY_ID_CODE,
        NULLIF(TRIM(FIRSTNAME),'')                                                 AS FIRST_NAME,
        NULLIF(TRIM(GENDER),'')                                                    AS GENDER,
        CAST(HIREDATE AS DATE)                                                     AS HIRE_DATE,
        ISINACTIVE                                                                 AS IS_INACTIVE,
        ISSALESREP                                                                 AS IS_SALES_REP,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        NULLIF(TRIM(LASTNAME),'')                                                  AS LAST_NAME,
        CAST(LOCATION AS NUMBER(38,0))                                             AS LOCATION_ID,
        NULLIF(TRIM(MOBILEPHONE),'')                                               AS MOBILE_PHONE,
        NULLIF(TRIM(PHONE),'')                                                     AS PHONE,
        CAST(SUBSIDIARY AS NUMBER(38,0))                                           AS SUBSIDIARY_ID,
        CAST(SUPERVISOR AS NUMBER(38,0))                                           AS SUPERVISOR_ID,
        NULLIF(TRIM(TITLE),'')                                                     AS TITLE

    FROM source

),

final AS (

    SELECT
        renamed.*,

        NOT COALESCE(renamed.IS_INACTIVE, FALSE)                                   AS IS_ACTIVE,

        {% if is_incremental() %}
        COALESCE(
            (SELECT MIN(existing.SILVER_CREATED_ON_TS_UTC)
             FROM {{ this }} existing
             WHERE existing.SURROGATE_KEY = renamed.SURROGATE_KEY),
            SYSDATE()
        )                                                                    AS SILVER_CREATED_ON_TS_UTC,
        {% else %}
        SYSDATE()                                 AS SILVER_CREATED_ON_TS_UTC,
        {% endif %}
        SYSDATE()                                 AS SILVER_UPDATED_ON_TS_UTC,
        CAST(NULL AS TIMESTAMP_NTZ)                             AS SILVER_DELETED_ON_TS_UTC

    FROM renamed

)

SELECT * FROM final
