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
  Model    : stg_ns_transactionline
  Layer    : staging (Silver)  ->  BUI_SAURAV_JHA_DB.SILVER
  Grain    : 1 row per TRANSACTIONLINE
  Schema   : static (explicit column list from reconciled Silver LLD)
  Cleaning : inline (DT-1/DT-2/DT-3/DT-4)
  PK       : SURROGATE_KEY  (natural key: UNIQUEKEY)
  Watermark: LINELASTMODIFIEDDATE
  Source   : {{ source('ns', 'TRANSACTIONLINE') }}
#}

WITH source AS (

    SELECT *
    FROM {{ source('ns', 'TRANSACTIONLINE') }}
    {% if is_incremental() %}
    WHERE LINELASTMODIFIEDDATE > (SELECT MAX(SILVER_UPDATED_ON_TS_UTC) FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        MD5(CAST(UNIQUEKEY AS VARCHAR) || '|' || 'NS')                             AS SURROGATE_KEY,
        CAST("TRANSACTION" AS NUMBER(38,0))                                        AS TRANSACTION_ID,
        CAST(ID AS NUMBER(38,0))                                                   AS LINE_ID,
        NULLIF(TRIM(ACCOUNTINGLINETYPE),'')                                        AS ACCOUNTING_LINE_TYPE,
        CAST(CLASS AS NUMBER(38,0))                                                AS CLASS_ID,
        CAST(DEPARTMENT AS NUMBER(38,0))                                           AS DEPARTMENT_ID,
        CAST(ENTITY AS NUMBER(38,0))                                               AS ENTITY_ID,
        CAST(FOREIGNAMOUNT AS NUMBER(38,6))                                        AS FOREIGN_AMOUNT,
        ISBILLABLE                                                                 AS IS_BILLABLE,
        ISCLOSED                                                                   AS IS_CLOSED,
        ISCOGS                                                                     AS IS_COGS,
        CAST(ITEM AS NUMBER(38,0))                                                 AS ITEM_ID,
        CAST(LINELASTMODIFIEDDATE AS TIMESTAMP_NTZ)                                AS LINE_LAST_MODIFIED_TS_ORIGINAL,
        CONVERT_TIMEZONE('America/Los_Angeles','UTC', LINELASTMODIFIEDDATE)        AS LINE_LAST_MODIFIED_TS_UTC,
        CAST(LINESEQUENCENUMBER AS NUMBER(38,0))                                   AS LINE_SEQUENCE_NUMBER,
        CAST(LOCATION AS NUMBER(38,0))                                             AS LOCATION_ID,
        MAINLINE                                                                   AS IS_MAIN_LINE,
        NULLIF(TRIM(MEMO),'')                                                      AS MEMO,
        CAST(NETAMOUNT AS NUMBER(38,6))                                            AS NET_AMOUNT,
        CAST(QUANTITY AS NUMBER(38,6))                                             AS QUANTITY,
        CAST(RATE AS NUMBER(38,6))                                                 AS RATE,
        CAST(SUBSIDIARY AS NUMBER(38,0))                                           AS SUBSIDIARY_ID,
        TAXLINE                                                                    AS IS_TAX_LINE,
        NULLIF(TRIM(TRANSACTIONLINETYPE),'')                                       AS TRANSACTION_LINE_TYPE,
        CAST(UNIQUEKEY AS NUMBER(38,0))                                            AS UNIQUE_KEY

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
