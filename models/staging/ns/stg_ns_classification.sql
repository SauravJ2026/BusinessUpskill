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
  Model    : stg_ns_classification
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per CLASSIFICATION
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'CLASSIFICATION') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'CLASSIFICATION') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        NULLIF(TRIM(FULLNAME),'')                                                  AS FULL_NAME,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        NULLIF(TRIM(NAME),'')                                                      AS NAME,
        CAST(PARENT AS NUMBER(38,0))                                               AS PARENT_ID,
        ISINACTIVE                                                                 AS IS_INACTIVE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        NULLIF(TRIM(SUBSIDIARY),'')                                                AS SUBSIDIARY

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
            {{ dbt.current_timestamp_in_utc() }}
        )                                                                    AS SILVER_CREATED_ON_TS_UTC,
        {% else %}
        {{ dbt.current_timestamp_in_utc() }}                                 AS SILVER_CREATED_ON_TS_UTC,
        {% endif %}
        {{ dbt.current_timestamp_in_utc() }}                                 AS SILVER_UPDATED_ON_TS_UTC,
        CAST(NULL AS {{ dbt.type_timestamp() }})                             AS SILVER_DELETED_ON_TS_UTC

    FROM renamed

)

SELECT * FROM final
