{#
    format_state regression: pins current behaviour, which this branch did not change --
    INCLUDING the known-wrong ZIP answers (see the macro header), so a silent "fix" fails
    here. format_state_province is the corrected version. Each case: (state, zip,
    expected state only, expected with zip).
#}
{%- set cases = [] -%}

{%- do cases.extend([
    ('California',    None,      'CA', 'CA'),
    ('new york',      None,      'NY', 'NY'),
    ('Washington DC', None,      'DC', 'DC'),
    ('Ontario',       None,      None, None),
    ('NY',            '90210',   'NY', 'NY'),
    (None,            '90210',   None, 'CA'),
    (None,            'M5V 3A8', None, None),
]) -%}

{# Known wrong, pinned deliberately #}
{%- do cases.extend([
    (None,            '96799',   None, 'HI'),
    (None,            '96950',   None, 'GU'),
    (None,            '00802',   None, 'PR'),
    (None,            '20201',   None, 'VA'),
    (None,            '75701',   None, 'AR'),
    (None,            '2134',    None, 'MD'),
]) -%}

with cases as (
    {{ case_rows(['state', 'zip', 'expected_state_only', 'expected_with_zip'], cases) }}
)

select
    *,
    {{ dbt_dataloft.format_state('state') }} as actual_state_only,
    {{ dbt_dataloft.format_state('state', 'zip') }} as actual_with_zip
from cases
