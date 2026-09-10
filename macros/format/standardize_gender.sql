{#
    Standardise gender values to 'Male', 'Female', 'Other', or null.

    Ported unchanged from the originating client project's `standardize_gender` — no dialect edits were needed.
    The `::varchar` cast was verified to work on both DuckDB and Snowflake. If a
    BigQuery-targeted project is ever added it will need `cast(... as string)`, since
    BigQuery has no `::` operator.

    Handles: M / Male / boys -> Male; F / Female / girls -> Female; anything starting
    with 'o' -> Other. Note the trailing wildcard is deliberately broad.

    Usage:
        {{ dbt_dataloft.standardize_gender('gender') }}
#}
{% macro standardize_gender(gender_expr) %}
case
    when lower(trim(coalesce({{ gender_expr }}, '')::varchar)) in ('m', 'male', 'boys') then 'Male'
    when lower(trim(coalesce({{ gender_expr }}, '')::varchar)) in ('f', 'female', 'girls') then 'Female'
    when lower(trim(coalesce({{ gender_expr }}, '')::varchar)) like 'o%' then 'Other'
    else null
end
{% endmacro %}
