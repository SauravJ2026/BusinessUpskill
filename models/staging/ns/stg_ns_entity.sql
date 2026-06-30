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
  Model    : stg_ns_entity
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per ENTITY
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'ENTITY') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'ENTITY') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        CAST(CUSTOMER AS NUMBER(38,0))                                             AS CUSTOMER_ID,
        CAST(DATECREATED AS TIMESTAMP_NTZ)                                         AS DATE_CREATED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', DATECREATED)                 AS DATE_CREATED_TS_UTC,
        NULLIF(TRIM(EMAIL),'')                                                     AS EMAIL,
        CAST(EMPLOYEE AS NUMBER(38,0))                                             AS EMPLOYEE_ID,
        NULLIF(TRIM(ENTITYTITLE),'')                                               AS ENTITY_TITLE,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        CAST(PARENT AS NUMBER(38,0))                                               AS PARENT_ID,
        CAST(PARTNER AS NUMBER(38,0))                                              AS PARTNER_ID,
        NULLIF(TRIM(PHONE),'')                                                     AS PHONE,
        CAST(TOPLEVELPARENT AS NUMBER(38,0))                                       AS TOP_LEVEL_PARENT_ID,
        NULLIF(TRIM(TYPE),'')                                                      AS ENTITY_TYPE,
        CAST(VENDOR AS NUMBER(38,0))                                               AS VENDOR_ID,
        NULLIF(TRIM(CUSTOMER_TYPE),'')                                             AS CUSTOMER_TYPE,
        NULLIF(TRIM(CUSTOMER_STATUS),'')                                           AS CUSTOMER_STATUS,
        TRY_CAST(NULLIF(TRIM(CREDIT_LIMIT),'') AS NUMBER(38,2))                    AS CREDIT_LIMIT,
        ISINACTIVE                                                                 AS IS_INACTIVE,
        NULLIF(TRIM(ENTITYID),'')                                                  AS ENTITY_ID_CODE,
        ISPERSON                                                                   AS IS_PERSON,
        NULLIF(TRIM(FULLNAME),'')                                                  AS FULL_NAME

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
