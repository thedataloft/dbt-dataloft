{#
    Normalise a North American phone number to E.164 (+1XXXXXXXXXX), or null.

    Ported from the originating client project's `generate_formated_phone`. Behaviour is unchanged; the only
    edit is routing `regexp_like` through the dialect shim so it runs on DuckDB as
    well as Snowflake.

    **NORTH AMERICA ONLY, AND IT CANNOT DETECT OTHERWISE.** This is the sharpest edge in
    the package. A ten-digit number starting 2-9 is assumed to be NANP and gets `+1`
    prepended. Many international numbers fit that shape: a London landline written
    `2071234567` becomes `+12071234567`, which is a valid-looking Maine number. There is
    no pattern that distinguishes them, because there genuinely isn't one — the
    information is not in the digits.

    So: **only apply this to a column you know is North American.** If the source can
    contain international numbers, branch on the source's own country field first, or
    leave the column raw and normalise downstream with a library that takes a region hint.
    Passing mixed international data through this macro produces confidently wrong output,
    not nulls. Verified 2026-08-27.

    Args:
        phone_number: column or expression holding digits (no punctuation stripping
                      is performed here — clean upstream if the source has any)

    Usage:
        {{ dbt_dataloft.format_phone('phone') }}
#}
{% macro format_phone(phone_number) %}
    case
        -- Already formatted correctly
        when length({{ phone_number }}) = 12 and left({{ phone_number }}, 2) = '+1'
            then {{ phone_number }}

        -- 10 digits: assume North American, add +1
        when length({{ phone_number }}) = 10
            and {{ dbt_dataloft.regex_matches(phone_number, '^[2-9][0-9]{9}$') }}
            then concat('+1', {{ phone_number }})

        -- 11 digits starting with 1: add +
        when length({{ phone_number }}) = 11
            and left({{ phone_number }}, 1) = '1'
            and {{ dbt_dataloft.regex_matches(phone_number, '^1[2-9][0-9]{9}$') }}
            then concat('+', {{ phone_number }})

        -- Invalid or non-North American
        else null
    end
{% endmacro %}
