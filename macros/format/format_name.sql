{% macro format_name(name_field) %}
    {#--
        Proper-case a personal or place name: first letter of each word upper, the rest lower,
        whitespace trimmed. Snowflake INITCAP default semantics on every adapter: a "word" is a run
        of letters, digits and apostrophes; every other character (space, hyphen, period,
        underscore) is a delimiter and is kept. So VAN DER BERG -> Van Der Berg, mary-jane ->
        Mary-Jane, émilie -> Émilie -- and o'brien -> O'brien, because Snowflake does not treat the
        apostrophe as a delimiter and identical output on both adapters is the contract here.
        Verified side by side, 9 cases, 2026-09-10.

        Why a macro: dbt-coding-standards mandates proper-cased names, and the obvious
        initcap(trim(x)) does not exist on DuckDB (Catalog Error, verified 2026-09-10 on 1.5.5).
        The first DuckDB client hit it on its first staging model.

        Usage:
            {{ dbt_dataloft.format_name('first_name') }} as first_name
    #}
    {{ return(adapter.dispatch('format_name', 'dbt_dataloft')(name_field)) }}
{% endmacro %}

{% macro default__format_name(name_field) %}
    {#-- DuckDB: split into word runs (letters, digits, apostrophes -- Snowflake's default word
         characters) and delimiter runs; upper the first character of every run (a no-op on a
         delimiter run), keep the rest lowercased. \p{L}/\p{N} rather than [a-z0-9] so accented
         letters count. Python-style lambda: the `t -> ...` form is deprecated in DuckDB 1.3+. --#}
    case
        when {{ name_field }} is null then null
        -- string_agg over an empty list is null on DuckDB; Snowflake's initcap('') is ''. Match Snowflake.
        when trim({{ name_field }}) = '' then ''
        else list_aggregate(
            list_transform(
                regexp_extract_all(lower(trim({{ name_field }})), '[\p{L}\p{N}'']+|[^\p{L}\p{N}'']+'),
                lambda t: upper(t[1]) || t[2:]
            ),
            'string_agg', ''
        )
    end
{% endmacro %}

{% macro snowflake__format_name(name_field) %}
    initcap(trim({{ name_field }}))
{% endmacro %}
