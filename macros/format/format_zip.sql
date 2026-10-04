{#
    Normalise a US ZIP to five digits, or null.

    Ported from the originating client project's `generate_formated_zip`. Behaviour is unchanged; the edits are
    routing `regexp_replace` and `regexp_like` through the dialect shims, and the
    varchar cast through `as_string` for BigQuery, which has no VARCHAR type. Note the
    original used Snowflake's 4-arg `regexp_replace(x, p, r, 1, 0)`, whose position=1
    occurrence=0 means "replace every match" — `regex_replace_all` preserves that
    meaning on both adapters.

    Handles ZIP+4 by taking the first five digits, and pads numeric inputs that lost
    a leading zero. Rejects anything outside the real US range (00501–99950), and
    anything containing a letter — see the guard in the body.

    **US only.** Feed it a Canadian or UK postcode and you get null, which is correct
    but means this macro cannot normalise non-US postal codes. For Canadian postal codes
    as well, use `format_postal`.

    Args:
        zip_code_field: column or expression

    Usage:
        {{ dbt_dataloft.format_zip('postal_code') }}
#}
{% macro format_zip(zip_code_field) %}
    {%- set cleaned_zip = dbt_dataloft.regex_replace_all('trim(' ~ dbt_dataloft.as_string(zip_code_field) ~ ')', '[^0-9]', '') -%}
    {%- set formatted_zip = "left(lpad(" ~ cleaned_zip ~ ", 5, '0'), 5)" -%}

    case
        -- A US ZIP never contains a letter; a Canadian postal code always does, and a UK
        -- one usually does. Without this guard 'M5V 3A8' strips to '538', pads to '00538'
        -- and passes the range check below — a plausible-looking US ZIP invented from
        -- Canadian data. Silent corruption, so it is checked first. Verified 2026-08-27.
        when {{ dbt_dataloft.regex_contains(dbt_dataloft.as_string(zip_code_field), '[A-Za-z]') }}
            then null

        -- Null or empty once non-digits are stripped
        when {{ cleaned_zip }} is null or {{ cleaned_zip }} = '' or length({{ cleaned_zip }}) = 0
            then null

        -- Exactly five digits, numeric, inside the valid US range
        when length({{ formatted_zip }}) = 5
            and {{ dbt_dataloft.regex_matches(formatted_zip, '^[0-9]{5}$') }}
            and cast({{ formatted_zip }} as integer) between 501 and 99950
            then {{ formatted_zip }}

        -- Invalid zip code
        else null
    end
{% endmacro %}
