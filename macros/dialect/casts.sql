{#
    Dialect shim for casting to a string type.

    DuckDB and Snowflake both accept `varchar`. BigQuery does not -- there is no VARCHAR
    type and no `::` cast operator on BigQuery, only `cast(x as string)`. Added
    2026-09-21, verified against a live instance 2026-09-25.
#}

{% macro as_string(expr) %}
  {{ return(adapter.dispatch('as_string', 'dbt_dataloft')(expr)) }}
{% endmacro %}

{% macro default__as_string(expr) %}
cast({{ expr }} as varchar)
{% endmacro %}

{% macro bigquery__as_string(expr) %}
cast({{ expr }} as string)
{% endmacro %}
