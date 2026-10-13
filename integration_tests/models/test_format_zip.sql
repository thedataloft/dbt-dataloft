{#
    format_zip regression: pins current behaviour, which this branch did not change.
    Each case: (input, expected).
#}
{%- set cases = [
    ('90210',      '90210'),
    ('90210-1234', '90210'),
    (' 12345 ',    '12345'),
    ('2134',       '02134'),
    ('00500',      None),
    ('00501',      '00501'),
    ('99950',      '99950'),
    ('99951',      None),
    ('1234567890', '12345'),
    ('M5V 3A8',    None),
    ('',           None),
    (None,         None),
] -%}

with cases as (
    {{ case_rows(['input', 'expected'], cases) }}
)

select
    *,
    {{ dbt_dataloft.format_zip('input') }} as actual
from cases
