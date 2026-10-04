{#
    format_postal, with and without a country. Each case: (input, country, expected
    without country, expected with country). Postal codes are generic or well-known
    public ones (K1A 0B1 is Canada Post's own; 90210 a famous ZIP), not anyone's address.
#}
{%- set cases = [] -%}

{# US, shape-detected: same as format_zip #}
{%- do cases.extend([
    ('90210',       None,            '90210',   '90210'),
    ('90210-1234',  None,            '90210',   '90210'),
    ('2134',        None,            '02134',   '02134'),
    ('00500',       None,            None,      None),
    ('99951',       None,            None,      None),
]) -%}

{# Canada, any spacing/case/punctuation in, 'A1A 1A1' out #}
{%- do cases.extend([
    ('K1A 0B1',     None,            'K1A 0B1', 'K1A 0B1'),
    ('k1a0b1',      None,            'K1A 0B1', 'K1A 0B1'),
    ('K1A-0B1',     None,            'K1A 0B1', 'K1A 0B1'),
    (' m5v 3a8 ',   None,            'M5V 3A8', 'M5V 3A8'),
    ('K1W 0Z1',     None,            'K1W 0Z1', 'K1W 0Z1'),
]) -%}

{# Letters Canada Post never uses #}
{%- do cases.extend([
    ('D1A 0B1',     None,            None,      None),
    ('W1A 0B1',     None,            None,      None),
    ('Z1A 0B1',     None,            None,      None),
    ('K1A 0O1',     None,            None,      None),
    ('K1U 0B1',     None,            None,      None),
]) -%}

{# Neither shape #}
{%- do cases.extend([
    ('K1A0B',       None,            None,      None),
    ('SW1A 1AA',    None,            None,      None),
    ('',            None,            None,      None),
    (None,          None,            None,      None),
]) -%}

{# Country given: must fit that country; other recognised countries are null #}
{%- do cases.extend([
    ('90210',       'US',            '90210',   '90210'),
    ('90210',       'Canada',        '90210',   None),
    ('K1A 0B1',     'canada',        'K1A 0B1', 'K1A 0B1'),
    ('K1A 0B1',     'United States', 'K1A 0B1', None),
    ('K1A 0B1',     'Mexico',        'K1A 0B1', None),
    ('06600',       'MX',            '06600',   None),
]) -%}

{# Country unrecognised: falls back to the shape #}
{%- do cases.extend([
    ('90210',       'Narnia',        '90210',   '90210'),
    ('K1A 0B1',     'Narnia',        'K1A 0B1', 'K1A 0B1'),
]) -%}

with cases as (
    {{ case_rows(['input', 'country', 'expected_no_country', 'expected_with_country'], cases) }}
)

select
    *,
    {{ dbt_dataloft.format_postal('input') }} as actual_no_country,
    {{ dbt_dataloft.format_postal('input', 'country') }} as actual_with_country
from cases
