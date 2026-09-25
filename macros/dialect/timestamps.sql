{#
    Dialect shims for timezone-aware timestamps.

    Verified 2026-08-13 against DuckDB 1.5.x: neither `convert_timezone` nor
    `timestamp_tz_from_parts` exists on DuckDB. Both fail loudly (Catalog Error), so
    unlike the regex divergences there is no silent-wrong-answer risk here.

    SEMANTIC DIFFERENCE, worth understanding before relying on these. Snowflake's
    TIMESTAMP_TZ retains the source UTC offset as part of the value, so
    `convert_timezone('UTC', x)` genuinely rewrites the offset to +00:00. DuckDB's
    TIMESTAMPTZ does not store an offset at all -- it is an absolute instant, held as
    UTC and merely *rendered* in the session timezone. So on DuckDB the cast alone
    normalises the instant and there is nothing further to convert.

    The consequence: both adapters agree on the instant, and therefore on any
    comparison, join or arithmetic. They may disagree on the rendered offset in a
    string. Store and compare these values; do not assert on their text.

    UNPARSEABLE INPUT YIELDS NULL, NOT AN ERROR. These use `try_cast`, which both
    adapters support with the same keyword. A plain `::` cast fails the whole build on a
    single bad row, and an empty-string timestamp is extremely common in real extracts —
    CSV-to-parquet conversions produce '' far more often than NULL. Degrading to null
    matches every other macro in this package, which return null for input they cannot
    parse. Verified on both adapters 2026-08-27.

    ONE DIVERGENCE `try_cast` DOES NOT HIDE. An all-digit string is a valid timestamp to
    Snowflake and not to DuckDB. `try_cast('90210' as timestamp_tz)` yields
    1970-01-02 01:03:30 on Snowflake — 90210 seconds after the epoch — and null on DuckDB.
    Both are defensible: Snowflake supports epoch strings, DuckDB is stricter. Neither is
    wrong, so this is not normalised.

    The consequence is real though: **if a timestamp column can contain a bare number,
    these macros give different answers per adapter.** If the column genuinely holds epoch
    values, convert it explicitly rather than relying on the cast. If it does not, guard
    the input. Verified 2026-08-27.

    BigQuery variants added 2026-09-21, verified against a live instance 2026-09-25.
    BigQuery's TIMESTAMP matches DuckDB's semantics here, not Snowflake's: it is an
    absolute instant stored without a retained source offset. There is no try_cast on
    BigQuery; safe_cast is the equivalent (NULL on failure rather than an error) and is
    used throughout.

    bigquery__make_timestamp_tz needed verifying separately: both of its callers --
    add_local_timezone and date_to_local_timestamp -- have their own bigquery__
    implementations that build the timestamp directly and never decompose into parts, so
    no model exercises it. Calling it directly with literal parts covers it. Whole
    seconds agree with DuckDB; a fractional second does not. See its own comment below.
#}

{#-- Normalise an expression to a UTC-aligned timezone-aware timestamp. --#}
{% macro to_utc_tz(expr) %}
  {{ return(adapter.dispatch('to_utc_tz', 'dbt_dataloft')(expr)) }}
{% endmacro %}

{% macro default__to_utc_tz(expr) %}
try_cast({{ expr }} as timestamptz)
{% endmacro %}

{% macro snowflake__to_utc_tz(expr) %}
convert_timezone('UTC', try_cast({{ expr }} as timestamp_tz))
{% endmacro %}

{% macro bigquery__to_utc_tz(expr) %}
safe_cast({{ expr }} as timestamp)
{% endmacro %}


{#-- Build a timezone-aware timestamp from parts. Snowflake takes a nanoseconds
     argument that DuckDB has no slot for; it is fixed at 0, matching the original. --#}
{% macro make_timestamp_tz(year, month, day, hour, minute, second, timezone) %}
  {{ return(adapter.dispatch('make_timestamp_tz', 'dbt_dataloft')(year, month, day, hour, minute, second, timezone)) }}
{% endmacro %}

{% macro default__make_timestamp_tz(year, month, day, hour, minute, second, timezone) %}
make_timestamptz({{ year }}, {{ month }}, {{ day }}, {{ hour }}, {{ minute }}, ({{ second }}) :: double, {{ timezone }})
{% endmacro %}

{% macro snowflake__make_timestamp_tz(year, month, day, hour, minute, second, timezone) %}
timestamp_tz_from_parts({{ year }}, {{ month }}, {{ day }}, {{ hour }}, {{ minute }}, {{ second }}, 0, {{ timezone }})
{% endmacro %}

{#-- BigQuery has no from-parts timestamp constructor; build a DATETIME from the parts,
     then attach the timezone with timestamp(datetime, tz).

     Verified against DuckDB 2026-09-25 for WHOLE seconds, including DST in both
     directions -- called directly, since both wrappers bypass this macro on BigQuery.

     FRACTIONAL SECONDS DIVERGE, and not in the direction an earlier version of this
     comment claimed. DATETIME()'s seconds argument is INT64, and BigQuery's CAST to
     INT64 ROUNDS half away from zero rather than truncating (measured: 30.5 -> 31,
     30.4 -> 30, 31.5 -> 32). So second = 30.5 gives :30.5 on DuckDB, whose slot is a
     double, and :31 here. Left as-is deliberately, like the all-digit-string divergence
     documented in SKILL.md: it is unreachable through add_local_timezone or
     date_to_local_timestamp, both of which pass whole seconds -- DuckDB's second()
     returns BIGINT, and date_to_local_timestamp passes a literal 0.

     **Pass whole seconds if you call this macro directly.** #}
{% macro bigquery__make_timestamp_tz(year, month, day, hour, minute, second, timezone) %}
timestamp(datetime({{ year }}, {{ month }}, {{ day }}, {{ hour }}, {{ minute }}, cast(({{ second }}) as int64)), {{ timezone }})
{% endmacro %}


{#-- The current instant, timezone-aware, UTC-aligned. --#}
{% macro current_timestamp_utc() %}
  {{ return(adapter.dispatch('current_timestamp_utc', 'dbt_dataloft')()) }}
{% endmacro %}

{% macro default__current_timestamp_utc() %}
now()
{% endmacro %}

{% macro snowflake__current_timestamp_utc() %}
convert_timezone('UTC', current_timestamp() :: timestamp_tz)
{% endmacro %}

{% macro bigquery__current_timestamp_utc() %}
current_timestamp()
{% endmacro %}
