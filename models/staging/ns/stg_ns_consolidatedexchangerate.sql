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
  Model    : stg_ns_consolidatedexchangerate
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per CONSOLIDATEDEXCHANGERATE
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: none in Bronze — full source scan + merge each run
  Source   : {{ source('ns', 'CONSOLIDATEDEXCHANGERATE') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'CONSOLIDATEDEXCHANGERATE') }}


),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        CAST(AVERAGERATE AS NUMBER(38,6))                                          AS AVERAGE_RATE,
        CAST(CURRENTRATE AS NUMBER(38,6))                                          AS CURRENT_RATE,
        CAST(FROMCURRENCY AS NUMBER(38,0))                                         AS FROM_CURRENCY_ID,
        CAST(FROMSUBSIDIARY AS NUMBER(38,0))                                       AS FROM_SUBSIDIARY_ID,
        CAST(HISTORICALRATE AS NUMBER(38,6))                                       AS HISTORICAL_RATE,
        CAST(PERIODSTARTDATE AS DATE)                                              AS PERIOD_START_DATE,
        CAST(POSTINGPERIOD AS NUMBER(38,0))                                        AS POSTING_PERIOD_ID,
        CAST(TOCURRENCY AS NUMBER(38,0))                                           AS TO_CURRENCY_ID,
        CAST(TOSUBSIDIARY AS NUMBER(38,0))                                         AS TO_SUBSIDIARY_ID

    FROM source

),

final AS (

    SELECT
        renamed.*,

        TRUE                                                                       AS IS_ACTIVE,

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
