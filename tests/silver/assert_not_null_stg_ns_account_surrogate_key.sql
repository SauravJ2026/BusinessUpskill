-- ============================================================
-- The output have been generated with the assistance of Claude at 2026-06-30T20:04:50Z UTC.
-- The content has been verified by the designated engineer.
-- ============================================================

SELECT *
FROM {{ ref('stg_ns_account') }}
WHERE SURROGATE_KEY IS NULL
