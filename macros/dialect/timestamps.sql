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
