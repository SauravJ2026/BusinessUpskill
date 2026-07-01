-- ============================================================
-- The output has been generated with the assistance of Claude at 2026-07-01T04:51:55Z.
-- The content has been verified by the designated engineer.
-- ============================================================

{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold','dimension','date'],
    on_schema_change = 'fail'
  )
}}

-- DIM_DATE | conformed calendar spine | Grain: one row per calendar date

WITH spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('2020-01-01')",
        end_date="to_date('2027-01-01')"
    ) }}
),
d AS (SELECT CAST(date_day AS DATE) AS cd FROM spine),
calendar AS (
    SELECT
        TO_NUMBER(TO_CHAR(cd,'YYYYMMDD'))            AS DATE_KEY,
        cd                                           AS CALENDAR_DATE,
        DECODE(DAYOFWEEKISO(cd),1,'Monday',2,'Tuesday',3,'Wednesday',4,'Thursday',5,'Friday',6,'Saturday',7,'Sunday') AS DAY_OF_WEEK,
        DAYOFWEEKISO(cd)                             AS DAY_OF_WEEK_NUM,
        DAYOFMONTH(cd)                               AS DAY_OF_MONTH,
        WEEKISO(cd)                                  AS WEEK_OF_YEAR,
        MONTH(cd)                                    AS MONTH_NUM,
        DECODE(MONTH(cd),1,'January',2,'February',3,'March',4,'April',5,'May',6,'June',7,'July',8,'August',9,'September',10,'October',11,'November',12,'December') AS MONTH_NAME,
        MONTHNAME(cd)                                AS MONTH_SHORT,
        QUARTER(cd)                                  AS QUARTER_NUM,
        'Q' || QUARTER(cd)                           AS QUARTER_NAME,
        YEAR(cd)                                     AS YEAR_NUM,
        YEAR(cd)                                     AS FISCAL_YEAR,
        QUARTER(cd)                                  AS FISCAL_QUARTER,
        DAYOFMONTH(LAST_DAY(cd))                     AS DAYS_IN_MONTH,
        (DAYOFWEEKISO(cd) IN (6,7))                  AS IS_WEEKEND,
        FALSE                                        AS IS_HOLIDAY
    FROM d
),
unknown AS (
    SELECT -1, TO_DATE('1900-01-01'), 'Unknown', 0, 0, 0, 0, 'Unknown', 'UNK', 0, 'UNK', 0, 0, 0, 0, FALSE, FALSE
)
SELECT * FROM calendar
UNION ALL
SELECT * FROM unknown
