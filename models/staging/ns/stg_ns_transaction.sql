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
  Model    : stg_ns_transaction
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per TRANSACTION
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: ID)
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'TRANSACTION') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'TRANSACTION') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(ID AS VARCHAR) || '|' || 'NS')                                    AS SURROGATE_KEY,
        CAST(ID AS NUMBER(38,0))                                                   AS ID,
        NULLIF(TRIM(ABBREVTYPE),'')                                                AS ABBREV_TYPE,
        CAST(APPROVALSTATUS AS NUMBER(38,0))                                       AS APPROVAL_STATUS_ID,
        CAST(CLOSEDATE AS DATE)                                                    AS CLOSE_DATE,
        CAST(CREATEDDATE AS TIMESTAMP_NTZ)                                         AS CREATED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', CREATEDDATE)                 AS CREATED_TS_UTC,
        CAST(CURRENCY AS NUMBER(38,0))                                             AS CURRENCY_ID,
        CAST(DUEDATE AS DATE)                                                      AS DUE_DATE,
        CAST(ENTITY AS NUMBER(38,0))                                               AS ENTITY_ID,
        CAST(EXCHANGERATE AS NUMBER(38,6))                                         AS EXCHANGE_RATE,
        CAST(FOREIGNTOTAL AS NUMBER(38,6))                                         AS FOREIGN_TOTAL,
        CAST(INTERCOTRANSACTION AS NUMBER(38,0))                                   AS INTERCO_TRANSACTION_ID,
        ISREVERSAL                                                                 AS IS_REVERSAL,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        NULLIF(TRIM(MEMO),'')                                                      AS MEMO,
        POSTING                                                                    AS IS_POSTING,
        CAST(POSTINGPERIOD AS NUMBER(38,0))                                        AS POSTING_PERIOD_ID,
        NULLIF(TRIM(RECORDTYPE),'')                                                AS RECORD_TYPE,
        NULLIF(TRIM(STATUS),'')                                                    AS STATUS_CODE,
        CAST(TRANDATE AS DATE)                                                     AS TRANSACTION_DATE,
        NULLIF(TRIM(TRANDISPLAYNAME),'')                                           AS TRANSACTION_DISPLAY_NAME,
        NULLIF(TRIM(TRANID),'')                                                    AS DOCUMENT_NUMBER,
        NULLIF(TRIM(TRANSACTIONNUMBER),'')                                         AS TRANSACTION_NUMBER,
        NULLIF(TRIM(TYPE),'')                                                      AS TRANSACTION_TYPE,
        VOIDED                                                                     AS IS_VOIDED

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
