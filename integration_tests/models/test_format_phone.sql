{#
    format_phone, both modes. Each case: (input, expected default, expected
    allow_international). None is SQL null. Default-mode expectations are what the macro
    returned before allow_international existed -- that mode must not change.
#}
{#-- Every number is fictional: NANP 555-0100..0199, Ofcom's drama range 020 7946 0xxx,
     ARCEP's fiction range 01 99 00 xx xx. Keep it that way -- this repo is public. --#}
{%- set cases = [
    ('+44 20 7946 0123',      None,             '+442079460123'),
    ('(416) 555-0123',        None,             '+14165550123'),
    ('1-416-555-0123',        None,             '+14165550123'),
    ('+1 416 555 0123',       None,             '+14165550123'),
    ('+1 016 555 0123',       None,             None),
    ('2079460123',            '+12079460123',   '+12079460123'),
    ('+12',                   None,             None),
    ('',                      None,             None),
    (None,                    None,             None),
    ('020 7946 0123',         None,             None),

    ('4165550123',            '+14165550123',   '+14165550123'),
    ('14165550123',           '+14165550123',   '+14165550123'),
    ('+14165550123',          '+14165550123',   '+14165550123'),
    ('  4165550123  ',        None,             '+14165550123'),
    ('1165550123',            None,             None),
    ('24165550123',           None,             None),
    ('+1abcdefghij',          '+1abcdefghij',   None),
    ('+33 1 99 00 12 34',     None,             '+33199001234'),
    ('+44 7946 0',            None,             None),
    ('+44 7946 01',           None,             '+44794601'),
    ('+1 416 555 0123 4567',  None,             None),
    ('+44 20 7946 0123 456',  None,             '+442079460123456'),
    ('+44 20 7946 0123 4567', None,             None),
    ('+0 20 7946 0123',       None,             None),
    ('0044 20 7946 0123',     None,             None),
    ('011 44 20 7946 0123',   None,             None),
] -%}

with cases as (
    {{ case_rows(['input', 'expected_default', 'expected_international'], cases) }}
)

select
    *,
    {{ dbt_dataloft.format_phone('input') }} as actual_default,
    {{ dbt_dataloft.format_phone('input', allow_international=True) }} as actual_international
from cases
