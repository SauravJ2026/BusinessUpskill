<!-- ============================================================
     The output have been generated with the assistance of Claude at 2026-06-30T20:06:11Z UTC.
     The content has been verified by the designated engineer.
     ============================================================ -->

# Changelog

## 2026-06-30 — Silver staging v1
- Generated 15 `stg_ns_*` staging models + `_sources.yml` + per-model `_schema.yml` tests + 45 singular tests.
- Source: reconciled `silver_lld.xlsx` (298 columns, all 204 Bronze columns aligned).
- Applied 3 LLD flag fixes (TRANSACTION.POSTING/VOIDED booleans; TRANSACTIONSTATUS composite key).
