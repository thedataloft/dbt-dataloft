{#
    Standardise gender values to 'Male', 'Female', 'Other', or null.

    Ported unchanged from the originating client project's `standardize_gender`. The `::varchar` cast was
    verified to work on both DuckDB and Snowflake; BigQuery has no `::` operator and no
    VARCHAR type, so the cast now goes through the `as_string` dialect shim (added
    2026-09-21) instead of being hardcoded.

    Handles: M / Male / boys -> Male; F / Female / girls -> Female; anything starting
    with 'o' -> Other. Note the trailing wildcard is deliberately broad.

    Usage:
        {{ dbt_dataloft.standardize_gender('gender') }}
#}
{% macro standardize_gender(gender_expr) %}
    {%- set cleaned = dbt_dataloft.as_string("coalesce(" ~ gender_expr ~ ", '')") -%}
case
    when lower(trim({{ cleaned }})) in ('m', 'male', 'boys') then 'Male'
    when lower(trim({{ cleaned }})) in ('f', 'female', 'girls') then 'Female'
    when lower(trim({{ cleaned }})) like 'o%' then 'Other'
    else null
end
{% endmacro %}
