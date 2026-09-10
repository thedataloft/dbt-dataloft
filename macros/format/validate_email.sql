{#
    Return the lowercased, trimmed email if it is well-formed, else null.

    Ported from the originating client project's `return_validated_emails`. Two edits: `regexp_like` goes through
    the dialect shim, and the original's `\\.` escape is replaced with the `[.]`
    character class. That escape renders as '\\.' in SQL, which Snowflake unescapes to
    `\.` but DuckDB does not -- on DuckDB it silently matches nothing, so every address
    with a dotted domain would be rejected. `[.]` needs no escaping on either adapter.

    Usage:
        {{ dbt_dataloft.validate_email('email') }}
#}
{% macro validate_email(email_field) %}
    {%- set normalised = "lower(trim(" ~ email_field ~ "))" -%}
    {%- set pattern = "^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?([.][a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$" -%}
    case
        -- Valid: return the normalised address
        when {{ dbt_dataloft.regex_matches(normalised, pattern) }}
            then {{ normalised }}

        -- Invalid email format
        else null
    end
{% endmacro %}
