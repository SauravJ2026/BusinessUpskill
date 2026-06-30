<!-- ============================================================
     The output have been generated with the assistance of Claude at 2026-06-30T20:06:11Z UTC.
     The content has been verified by the designated engineer.
     ============================================================ -->

# PCP Silver Layer — dbt Staging Models

Silver staging for the **Pinnacle Capital Partners** Snowflake + dbt capstone. Generated from the
reconciled Silver LLD (`silver_lld.xlsx`) via the Silver Layer Scripts Generator methodology.

## What this is
15 one-to-one (1:1) staging models that clean and conform the Bronze NetSuite replica
(`BUI_SAURAV_JHA_DB.RAW.*`) into `BUI_SAURAV_JHA_DB.SILVER.STG_NS_*`. No joins, no unions —
each Bronze table maps to exactly one Silver table. Joins happen later in Gold.

## Layout
```
pcp_silver/
  dbt_project.yml          project config, vars (bronze/silver db + schema), staging=incremental/merge
  packages.yml             dbt_utils
  profiles.yml             TEMPLATE ONLY — do not commit; uses env vars
  macros/generate_schema_name.sql
  models/staging/ns/
    _sources.yml           15 RAW source tables
    stg_ns_<table>.sql     15 models (source -> renamed -> final CTE chain)
    stg_ns_<table>.yml     per-model tests (SURROGATE_KEY unique+not_null, audit not_null)
  tests/silver/            45 singular tests (3 per table)
```

## Models
- `stg_ns_account`
- `stg_ns_accountingperiod`
- `stg_ns_classification`
- `stg_ns_consolidatedexchangerate`
- `stg_ns_currency`
- `stg_ns_department`
- `stg_ns_employee`
- `stg_ns_entity`
- `stg_ns_item`
- `stg_ns_location`
- `stg_ns_subsidiary`
- `stg_ns_transaction`
- `stg_ns_transactionaccountingline`
- `stg_ns_transactionline`
- `stg_ns_transactionstatus`

## Conventions baked in
- **PK:** every table has `SURROGATE_KEY = MD5(<natural key> || '|' || 'NS')`, computed first in `renamed`, sole unique_key.
- **Cleaning:** DT-1 timestamp split (`_TS_ORIGINAL` + `_TS_UTC`, America/Los_Angeles -> UTC), DT-2 `NUMBER(38,6)` measures, DT-3 `NUMBER(38,0)` ids, DT-4 `NULLIF(TRIM(x),'')` text. Booleans pass through (Bronze already BOOLEAN).
- **Audit:** `IS_ACTIVE`, `SILVER_CREATED_ON_TS_UTC`, `SILVER_UPDATED_ON_TS_UTC`, `SILVER_DELETED_ON_TS_UTC` appended in `final`.
- **Incremental:** `merge` on `SURROGATE_KEY`; watermark `LASTMODIFIEDDATE` (or `LINELASTMODIFIEDDATE`). `CONSOLIDATEDEXCHANGERATE` and `TRANSACTIONSTATUS` have no Bronze timestamp -> full merge each run.

## Run
```bash
export DBT_SF_ACCOUNT=...    DBT_SF_USER=...      DBT_SF_PASSWORD=...
export DBT_SF_ROLE=...       DBT_SF_WAREHOUSE=... DBT_SF_DATABASE=BUI_SAURAV_JHA_DB
dbt deps
dbt run  --select tag:staging --target dev
dbt test --select tag:staging --target dev
```
See `design_decisions.md` for the full decision log and the items to verify against live data.
