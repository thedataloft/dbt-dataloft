{#
    Normalise a phone number to E.164, or null. North American only by default;
    `allow_international=True` also accepts numbers typed with a leading `+` country code.

    Ported from the originating client project's `generate_formated_phone`. Behaviour is unchanged; the only
    edit is routing `regexp_like` through the dialect shim so it runs on DuckDB and
    BigQuery as well as Snowflake. BigQuery verified 2026-09-25. The opt-in mode was added
    2026-10-04; with it off, the rendered SQL is byte-identical to before.

    DEFAULT MODE -- **NORTH AMERICA ONLY, AND IT CANNOT DETECT OTHERWISE.** This is the
    sharpest edge in the package. A ten-digit number starting 2-9 is assumed to be NANP and
    gets `+1` prepended. Many international numbers fit that shape: a London landline
    written `2079460123` becomes `+12079460123`, which is a valid-looking Maine number.
    There is no pattern that distinguishes them, because there genuinely isn't one — the
    information is not in the digits.

    So: **only apply the default mode to a column you know is North American.** If the
    source can contain international numbers, use `allow_international=True` on the value
    as typed, branch on the source's own country field first, or leave the column raw and
    normalise downstream with a library that takes a region hint. Passing mixed
    international data through the default mode produces confidently wrong output, not
    nulls. Verified 2026-08-27.

    `allow_international=True` -- pass the value AS TYPED (punctuation and all); the macro
    does its own cleaning, because stripping non-digits upstream destroys the `+`, which is
    the only evidence a number is international.
        - Leading `+` (after trimming): every non-digit after it is dropped. `+` and 8-15
          digits, first digit 1-9, is returned as E.164. A `+1` number must still pass the
          North American check (+1, then 2-9, then nine digits), otherwise null.
        - No leading `+`: non-digits are stripped and the default North American rules
          apply unchanged — so `2079460123` still becomes `+12079460123`. The opt-in
          recognises international numbers only when the `+` says so.
        - Everything else is null. Deliberately NOT handled, and left null: `00`/`011`
          international prefixes, numbers with missing digits, and guessing a country
          from length. The country code is checked for shape only, not against the ITU
          list, and the national part is not validated. Keep the raw value in its own
          column if you need to recover these.

    Args:
        phone_number:        column or expression. Default mode: digits only (no
                             punctuation stripping is performed — clean upstream).
                             Opt-in mode: the value as typed.
        allow_international: False (default) or True — see above

    Usage:
        {{ dbt_dataloft.format_phone('phone') }}
        {{ dbt_dataloft.format_phone('phone_raw', allow_international=True) }}
#}
{% macro format_phone(phone_number, allow_international=False) %}
    {%- if allow_international %}
    {%- set typed = "trim(" ~ dbt_dataloft.as_string(phone_number) ~ ")" -%}
    {%- set digits = dbt_dataloft.regex_replace_all(typed, '[^0-9]', '') -%}
    case
        -- Leading +: the country code was typed, so trust it
        when left({{ typed }}, 1) = '+' then
            case
                -- +1 must still be a valid North American number
                when left({{ digits }}, 1) = '1'
                    then case
                        when {{ dbt_dataloft.regex_matches(digits, '^1[2-9][0-9]{9}$') }}
                            then concat('+', {{ digits }})
                        else null
                    end
                -- Any other country code: 8-15 digits, not starting 0
                when {{ dbt_dataloft.regex_matches(digits, '^[1-9][0-9]{7,14}$') }}
                    then concat('+', {{ digits }})
                else null
            end

        -- No +: digits only, then the default North American rules
        else {{ dbt_dataloft.format_phone(digits) }}
    end
    {%- else %}
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
    {%- endif %}
{% endmacro %}
