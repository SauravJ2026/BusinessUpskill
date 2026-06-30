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
  Model    : stg_ns_account
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per ACCOUNT
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'ACCOUNT') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'ACCOUNT') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        NULLIF(TRIM(ACCOUNTSEARCHDISPLAYNAME),'')                                  AS ACCOUNT_SEARCH_DISPLAY_NAME,
        NULLIF(TRIM(ACCTNUMBER),'')                                                AS ACCOUNT_NUMBER,
        NULLIF(TRIM(ACCTTYPE),'')                                                  AS ACCOUNT_TYPE,
        CAST(CLASS AS NUMBER(38,0))                                                AS CLASS_ID,
        CAST(CURRENCY AS NUMBER(38,0))                                             AS CURRENCY_ID,
        NULLIF(TRIM(DEPARTMENT),'')                                                AS DEPARTMENT,
        NULLIF(TRIM(DESCRIPTION),'')                                               AS DESCRIPTION,
        NULLIF(TRIM(DISPLAYNAMEWITHHIERARCHY),'')                                  AS DISPLAY_NAME_WITH_HIERARCHY,
        ELIMINATE                                                                  AS ELIMINATE,
        NULLIF(TRIM(FULLNAME),'')                                                  AS FULL_NAME,
        ISINACTIVE                                                                 AS IS_INACTIVE,
        ISSUMMARY                                                                  AS IS_SUMMARY,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        CAST(LOCATION AS NUMBER(38,0))                                             AS LOCATION_ID,
        CAST(PARENT AS NUMBER(38,0))                                               AS PARENT_ID,
        NULLIF(TRIM(SSPECACCT),'')                                                 AS SPECIAL_ACCOUNT_TYPE,
        NULLIF(TRIM(SUBSIDIARY),'')                                                AS SUBSIDIARY,
        NULLIF(TRIM(CASHFLOWRATE),'')                                              AS CASH_FLOW_RATE

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
