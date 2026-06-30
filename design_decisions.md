<!-- ============================================================
     The output have been generated with the assistance of Claude at 2026-06-30T20:06:11Z UTC.
     The content has been verified by the designated engineer.
     ============================================================ -->

# Silver Scripts — Design Decisions

Generated 2026-06-30T20:06:11Z. Driven by `CAPSTONE_HANDOFF_v2.md` + the reconciled `silver_lld.xlsx`.

## Phase 0 — Inputs
- **Platform:** Snowflake. **Framework:** dbt Core/Cloud.
- **Project:** `pcp_silver`; **profile:** `pcp`.
- **Silver:** `BUI_SAURAV_JHA_DB.SILVER`. **Bronze:** `BUI_SAURAV_JHA_DB.RAW`. **Source code:** `ns` / literal `NS`.
- **Folder:** `models/staging/ns/`. Model files `stg_ns_<entity>.sql`.
- **Model design:** 1:1 Static + inline cleaning (no seed, no config-driven/macro dispatch — all 15 tables are 1:1).

## Phase 0E/0F — dbt design
- **Materialization (staging):** `incremental` (overrides the skill default `view`). Rationale: the LLD requires
  per-row audit timestamps with distinct insert vs update behaviour, soft-delete, dedup, and a 24h refresh —
  these need a persisted table, not a view.
- **Incremental strategy:** `merge` on `SURROGATE_KEY`. `on_schema_change: fail`.
- **Identifier quoting:** OFF. Snowflake uppercases unquoted identifiers, yielding `SILVER.STG_NS_<TABLE>`
  (matches the LLD) and resolving `RAW.<TABLE>` sources. Reserved-word columns (`ACCOUNT`, `TRANSACTION`)
  are explicitly double-quoted in SQL where referenced.

## Phase 1 — Standards
- **Type mapping:** TARGET_TYPE from the LLD verbatim. **Tests (1D):** `SURROGATE_KEY` unique+not_null per table,
  plus `SILVER_CREATED_ON_TS_UTC` / `SILVER_UPDATED_ON_TS_UTC` not_null. No accepted_values/relationships at Silver
  (those belong to Gold; adding them now risks `dbt test` failures on real data).
- **Watermark (per table):** `LASTMODIFIEDDATE` for the 12 natural-ID tables and TRANSACTIONACCOUNTINGLINE;
  `LINELASTMODIFIEDDATE` for TRANSACTIONLINE; `ITEM.LASTMODIFIEDDATE` is TEXT -> wrapped in `TRY_TO_TIMESTAMP_NTZ`;
  `CONSOLIDATEDEXCHANGERATE` and `TRANSACTIONSTATUS` have no Bronze timestamp -> no incremental filter (full merge).

## Flag fixes applied (from Phase 1 reconciliation sign-off)
1. `TRANSACTION.POSTING` — Bronze is BOOLEAN; pass through (was a T/F text cast that would error).
2. `TRANSACTION.VOIDED` — same.
3. `TRANSACTIONSTATUS` — dropped the zombie `ID` column (absent in Bronze); PK is now composite
   `RECORD_HASH` over (`TRANSACTION_TYPE`, `TRANSACTION_STATUS_ID`); `SURROGATE_KEY` derives from it.

## Items to verify against LIVE data (not blockers, but watch these on first run)
- **`ACCOUNT.CASHFLOWRATE`** is included (`CASH_FLOW_RATE`) because the handoff says it exists on the real
  `RAW.ACCOUNT` though it is missing from the Bronze metadata file. If `dbt run` errors
  "invalid identifier 'CASHFLOWRATE'", the column is genuinely absent — delete that one line from `stg_ns_account.sql`.
- **Timezone:** DT-1 uses the 3-arg `CONVERT_TIMEZONE('America/Los_Angeles','UTC', col)` per the handoff. If the
  Bronze timestamps are actually delivered in UTC (e.g. Fivetran), switch every `_TS_UTC` expression to the
  2-arg `CONVERT_TIMEZONE('UTC', col)` form, else values shift ~7-8h.
- **TEXT-typed reference columns** (e.g. `ACCOUNT.SUBSIDIARY`, `ITEM.INCOME_ACCOUNT`) are kept as `VARCHAR`
  with the bare name (no `_ID`) because Bronze stores them as TEXT — confirm the join keys in Gold accordingly.
