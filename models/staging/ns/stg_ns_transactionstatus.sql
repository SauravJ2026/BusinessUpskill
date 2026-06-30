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
  Model    : stg_ns_transactionstatus
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per TRANSACTIONSTATUS
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: composite (RECORD_HASH))
  Watermark: none in Bronze — full source scan + merge each run
  Source   : {{ source('ns', 'TRANSACTIONSTATUS') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'TRANSACTIONSTATUS') }}


),

renamed AS (

    SELECT
        MD5(CONCAT_WS('|', CAST(TRANSACTION_TYPE AS VARCHAR), CAST(TRANSACTION_STATUS_ID AS VARCHAR)) || '|' || 'NS') AS SURROGATE_KEY,
        MD5(CONCAT_WS('|', CAST(TRANSACTION_TYPE AS VARCHAR), CAST(TRANSACTION_STATUS_ID AS VARCHAR))) AS RECORD_HASH,
        CAST(TRANSACTION_STATUS_ID AS NUMBER(38,0))                                AS TRANSACTION_STATUS_ID,
        NULLIF(TRIM(TRANSACTION_STATUS_FULL_NAME),'')                              AS TRANSACTION_STATUS_FULL_NAME,
        NULLIF(TRIM(TRANSACTION_STATUS_NAME),'')                                   AS TRANSACTION_STATUS_NAME,
        CAST(TRAN_CUSTOM_TYPE_ID AS NUMBER(38,0))                                  AS TRAN_CUSTOM_TYPE_ID,
        NULLIF(TRIM(TRANSACTION_TYPE),'')                                          AS TRANSACTION_TYPE

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
