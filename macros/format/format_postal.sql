{#
    Normalise a US ZIP or Canadian postal code, or null.

    US: five digits, exactly as `format_zip` (which this calls) -- ZIP+4 truncated, lost
    leading zeros restored, range-checked.
    Canada: 'A1A 1A1' -- uppercase, single space, Canada Post's published form. Accepts
    any spacing, case or punctuation on input ('k1a0b1', 'K1A-0B1'). Rejects letters
    Canada Post never uses: D F I O Q U anywhere, and W or Z in the first position.

    Without `country_field` the country is read from the value's shape, which is
    unambiguous: a Canadian postal code always contains letters and a US ZIP never does.
    With it, the value must fit that country's format, and a recognised country other
    than US or CA returns null. An unrecognised or null country falls back to the shape.
    `country_field` goes through `format_country`, so 'Canada', 'CA' and 'canada' all work.

    Args:
        postal_field:  column or expression
        country_field: optional column or expression holding the country

    Usage:
        {{ dbt_dataloft.format_postal('postal_code') }}
        {{ dbt_dataloft.format_postal('postal_code', 'country') }}
#}
{% macro format_postal(postal_field, country_field=None) %}
    {%- set cleaned_ca = dbt_dataloft.regex_replace_all('upper(' ~ dbt_dataloft.as_string(postal_field) ~ ')', '[^A-Z0-9]', '') -%}
    {%- set us_postal = dbt_dataloft.format_zip(postal_field) -%}
    {%- set ca_postal -%}
    case
        when {{ dbt_dataloft.regex_matches(cleaned_ca, '^[ABCEGHJ-NPRSTVXY][0-9][ABCEGHJ-NPRSTV-Z][0-9][ABCEGHJ-NPRSTV-Z][0-9]$') }}
            then left({{ cleaned_ca }}, 3) || ' ' || right({{ cleaned_ca }}, 3)
        else null
    end
    {%- endset -%}

    {% if country_field is none %}
    -- Shape decides: format_zip rejects anything with a letter, and the Canadian
    -- pattern requires letters, so at most one of these is non-null.
    coalesce({{ ca_postal }}, {{ us_postal }})
    {% else %}
    case coalesce({{ dbt_dataloft.format_country(country_field) }}, '??')
        when 'US' then {{ us_postal }}
        when 'CA' then {{ ca_postal }}
        -- Country null or unrecognised: fall back to the shape
        when '??' then coalesce({{ ca_postal }}, {{ us_postal }})
        -- A recognised country this macro does not format
        else null
    end
    {% endif %}
{% endmacro %}
