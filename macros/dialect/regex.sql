{#
    Dialect shims for the regex divergences between Snowflake, DuckDB and BigQuery.

    Verified 2026-08-13 against DuckDB 1.5.x:
      - regexp_like       exists on Snowflake, NOT on DuckDB (regexp_matches)
      - regexp_replace    Snowflake's 4-arg (subject, pattern, replacement, position,
                          occurrence) does not bind on DuckDB, and DuckDB's 3-arg form
                          replaces only the FIRST match unless given the 'g' flag.
                          Snowflake's 3-arg form is already global.

    BigQuery variants added 2026-09-21, verified against a live instance 2026-09-25.

    `pattern` is a Jinja string and is emitted single-quoted. Escaping is dialect
    sensitive — keep patterns simple, and test any pattern containing a backslash on
    both adapters before relying on it.
#}

{#-- FULL MATCH. The pattern must describe the ENTIRE string.

     This is not a stylistic preference. Snowflake's `regexp_like` is implicitly anchored
     to the whole string; DuckDB's `regexp_matches` is a substring search. An anchored
     pattern (`^…$`) therefore means the same thing on both, and an UNANCHORED one does
     not — `'[A-Za-z]'` matches 'M5V 3A8' on DuckDB and fails on Snowflake.

     Always anchor. If you want substring semantics, use `regex_contains` below. --#}
{% macro regex_matches(expr, pattern) %}
  {{ return(adapter.dispatch('regex_matches', 'dbt_dataloft')(expr, pattern)) }}
{% endmacro %}

{% macro default__regex_matches(expr, pattern) %}
regexp_matches({{ expr }}, '{{ pattern }}')
{% endmacro %}

{% macro snowflake__regex_matches(expr, pattern) %}
regexp_like({{ expr }}, '{{ pattern }}')
{% endmacro %}

{#-- BigQuery has no separate full-match function; regexp_contains against an anchored
     (^…$) pattern is a full match. Every caller in this package anchors already. --#}
{% macro bigquery__regex_matches(expr, pattern) %}
regexp_contains({{ expr }}, '{{ pattern }}')
{% endmacro %}


{#-- SUBSTRING MATCH. True if the pattern appears anywhere in the string.

     Snowflake has no unanchored `regexp_like`, so this dispatches to `regexp_instr`
     rather than mangling the pattern with `.*` — wrapping would break any pattern that
     itself contains anchors or alternation. Verified on both adapters 2026-08-27. --#}
{% macro regex_contains(expr, pattern) %}
  {{ return(adapter.dispatch('regex_contains', 'dbt_dataloft')(expr, pattern)) }}
{% endmacro %}

{% macro default__regex_contains(expr, pattern) %}
regexp_matches({{ expr }}, '{{ pattern }}')
{% endmacro %}

{% macro snowflake__regex_contains(expr, pattern) %}
regexp_instr({{ expr }}, '{{ pattern }}') > 0
{% endmacro %}

{#-- BigQuery's regexp_contains is unanchored substring search natively -- no wrapping
     needed, unlike the snowflake__ shim above. --#}
{% macro bigquery__regex_contains(expr, pattern) %}
regexp_contains({{ expr }}, '{{ pattern }}')
{% endmacro %}


{% macro regex_replace_all(expr, pattern, replacement='') %}
  {{ return(adapter.dispatch('regex_replace_all', 'dbt_dataloft')(expr, pattern, replacement)) }}
{% endmacro %}

{% macro default__regex_replace_all(expr, pattern, replacement) %}
regexp_replace({{ expr }}, '{{ pattern }}', '{{ replacement }}', 'g')
{% endmacro %}

{% macro snowflake__regex_replace_all(expr, pattern, replacement) %}
regexp_replace({{ expr }}, '{{ pattern }}', '{{ replacement }}')
{% endmacro %}

{#-- BigQuery's regexp_replace replaces every match by default, like Snowflake's --
     no 'g' flag exists or is needed. --#}
{% macro bigquery__regex_replace_all(expr, pattern, replacement) %}
regexp_replace({{ expr }}, '{{ pattern }}', '{{ replacement }}')
{% endmacro %}


{#-- A literal apostrophe INSIDE a single-quoted SQL string literal.

     DuckDB and Snowflake take the SQL-standard doubled quote (''). BigQuery does not
     recognise it: it ends the string at the first quote and then reports the remainder
     as an adjacent literal --
       "Syntax error: concatenated string literals must be separated by whitespace"
     -- so the whole model fails to parse. Loud, not silent, but it fails the build.

     Dispatching the escape rather than rewriting the pattern keeps the DuckDB and
     Snowflake output byte-identical, so their 2026-08-27 verification still stands. --#}
     
{% macro escaped_quote() %}
  {{ return(adapter.dispatch('escaped_quote', 'dbt_dataloft')()) }}
{% endmacro %}

{% macro default__escaped_quote() %}{{ return("''") }}{% endmacro %}

{% macro bigquery__escaped_quote() %}{{ return("\\'") }}{% endmacro %}
