-- ============================================================
-- The output have been generated with the assistance of Claude at 2026-06-30T20:04:50Z UTC.
-- The content has been verified by the designated engineer.
-- ============================================================

SELECT SURROGATE_KEY, SILVER_CREATED_ON_TS_UTC
FROM {{ ref('stg_ns_transactionline') }}
WHERE SILVER_CREATED_ON_TS_UTC IS NULL
