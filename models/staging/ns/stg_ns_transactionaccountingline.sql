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
  Model    : stg_ns_transactionaccountingline
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per TRANSACTIONACCOUNTINGLINE
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: composite (RECORD_HASH))
  Watermark: LASTMODIFIEDDATE
  Source   : {{ source('ns', 'TRANSACTIONACCOUNTINGLINE') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'TRANSACTIONACCOUNTINGLINE') }}
    {% if is_incremental() %}
    WHERE LASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CONCAT_WS('|', CAST("TRANSACTION" AS VARCHAR), CAST(ACCOUNTINGBOOK AS VARCHAR), CAST(TRANSACTIONLINE AS VARCHAR), CAST("ACCOUNT" AS VARCHAR)) || '|' || 'NS') AS SURROGATE_KEY,
        MD5(CONCAT_WS('|', CAST("TRANSACTION" AS VARCHAR), CAST(ACCOUNTINGBOOK AS VARCHAR), CAST(TRANSACTIONLINE AS VARCHAR), CAST("ACCOUNT" AS VARCHAR))) AS RECORD_HASH,
        CAST("TRANSACTION" AS NUMBER(38,0))                                        AS TRANSACTION_ID,
        CAST(ACCOUNTINGBOOK AS NUMBER(38,0))                                       AS ACCOUNTING_BOOK_ID,
        CAST(TRANSACTIONLINE AS NUMBER(38,0))                                      AS TRANSACTION_LINE_ID,
        CAST("ACCOUNT" AS NUMBER(38,0))                                            AS ACCOUNT_ID,
        NULLIF(TRIM(ACCOUNTTYPE),'')                                               AS ACCOUNT_TYPE,
        CAST(AMOUNT AS NUMBER(38,6))                                               AS AMOUNT,
        CAST(AMOUNTPAID AS NUMBER(38,6))                                           AS AMOUNT_PAID,
        CAST(AMOUNTUNPAID AS NUMBER(38,6))                                         AS AMOUNT_UNPAID,
        CAST(CREDIT AS NUMBER(38,6))                                               AS CREDIT,
        CAST(DEBIT AS NUMBER(38,6))                                                AS DEBIT,
        CAST(EXCHANGERATE AS NUMBER(38,6))                                         AS EXCHANGE_RATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                    AS LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LASTMODIFIEDDATE)            AS LAST_MODIFIED_TS_UTC,
        CAST(NETAMOUNT AS NUMBER(38,6))                                            AS NET_AMOUNT,
        POSTING                                                                    AS IS_POSTING

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
