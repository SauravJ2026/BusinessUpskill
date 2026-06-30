-- ============================================================
-- The output have been generated with the assistance of Claude at 2026-06-30T20:04:50Z UTC.
-- The content has been verified by the designated engineer.
-- ============================================================

SELECT SURROGATE_KEY, COUNT(*) AS n
FROM {{ ref('stg_ns_account') }}
GROUP BY SURROGATE_KEY
HAVING COUNT(*) > 1
