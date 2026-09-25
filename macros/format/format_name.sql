{% macro format_name(name_field) %}
    {#--
        Proper-case a personal or place name: first letter of each word upper, the rest lower,
        whitespace trimmed. Snowflake INITCAP default semantics on every adapter: a "word" is a run
        of letters, digits and apostrophes; every other character (space, hyphen, period,
        underscore) is a delimiter and is kept. So VAN DER BERG -> Van Der Berg, mary-jane ->
        Mary-Jane, émilie -> Émilie -- and o'brien -> O'brien, because Snowflake does not treat the
        apostrophe as a delimiter and identical output on every adapter is the contract here.
        Verified side by side on DuckDB and Snowflake, 9 cases, 2026-09-10; on BigQuery
        against DuckDB, 2026-09-25.

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

{% macro bigquery__format_name(name_field) %}
    {#-- BigQuery's initcap(value[, delimiters]) accepts an explicit delimiter set. Its
         *default* delimiter set is documented only by one example (space and hyphen are
         delimiters); whether apostrophe is included by default is not confirmed by
         Google's docs, and this is precisely the divergence that makes O'Brien vs
         O'brien silent elsewhere in this file. So this does not rely on the default --
         it passes an explicit delimiter list (whitespace plus common ASCII punctuation)
         that omits the apostrophe, matching the Snowflake-default contract the DuckDB
         branch above also targets. Everything not listed as a delimiter, including
         accented Unicode letters, stays a word character.

         Added 2026-09-21. VERIFIED against a live BigQuery instance 2026-09-25 -- the
         gamble paid off: o'brien -> O'brien (not O'Brien), mary-jane -> Mary-Jane,
         emilie with an acute -> capitalised correctly, VAN DER BERG -> Van Der Berg,
         all byte-identical to DuckDB. Do not "simplify" this to a bare initcap(): the
         default delimiter set is what this explicitly avoids relying on. #}
    initcap(trim({{ name_field }}), ' \t\n\r!"#$%&()*+,-./:;<=>?@[]^_`{|}~')
{% endmacro %}
