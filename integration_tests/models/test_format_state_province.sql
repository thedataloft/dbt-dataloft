{#
    format_state_province in its three call shapes. Each case: (state, postal, country,
    expected state only, expected with postal, expected with postal and country).
#}
{%- set cases = [] -%}

{# Canadian names and codes, English and French, accented and not #}
{%- do cases.extend([
    ('Ontario',                   None, None, 'ON', 'ON', 'ON'),
    ('ON',                        None, None, 'ON', 'ON', 'ON'),
    ('Alberta',                   None, None, 'AB', 'AB', 'AB'),
    ('Alta.',                     None, None, 'AB', 'AB', 'AB'),
    ('British Columbia',          None, None, 'BC', 'BC', 'BC'),
    ('Colombie-Britannique',      None, None, 'BC', 'BC', 'BC'),
    ('Manitoba',                  None, None, 'MB', 'MB', 'MB'),
    ('New Brunswick',             None, None, 'NB', 'NB', 'NB'),
    ('Nouveau-Brunswick',         None, None, 'NB', 'NB', 'NB'),
    ('Newfoundland and Labrador', None, None, 'NL', 'NL', 'NL'),
    ('NF',                        None, None, 'NL', 'NL', 'NL'),
    ('Nova Scotia',               None, None, 'NS', 'NS', 'NS'),
    ('Nouvelle-Écosse',           None, None, 'NS', 'NS', 'NS'),
    ('Northwest Territories',     None, None, 'NT', 'NT', 'NT'),
    ('N.W.T.',                    None, None, 'NT', 'NT', 'NT'),
    ('Nunavut',                   None, None, 'NU', 'NU', 'NU'),
    ('Prince Edward Island',      None, None, 'PE', 'PE', 'PE'),
    ('P.E.I.',                    None, None, 'PE', 'PE', 'PE'),
    ('Île-du-Prince-Édouard',     None, None, 'PE', 'PE', 'PE'),
    ('ile du prince edouard',     None, None, 'PE', 'PE', 'PE'),
    ('Québec',                    None, None, 'QC', 'QC', 'QC'),
    ('québec',                    None, None, 'QC', 'QC', 'QC'),
    ('Quebec',                    None, None, 'QC', 'QC', 'QC'),
    ('PQ',                        None, None, 'QC', 'QC', 'QC'),
    ('Saskatchewan',              None, None, 'SK', 'SK', 'SK'),
    ('Yukon',                     None, None, 'YT', 'YT', 'YT'),
]) -%}

{# US, via format_state #}
{%- do cases.extend([
    ('California',                None, None, 'CA', 'CA', 'CA'),
    ('new york',                  None, None, 'NY', 'NY', 'NY'),
    ('D.C.',                      None, None, 'DC', 'DC', 'DC'),
    ('Narnia',                    None, None, None, None, None),
]) -%}

{# Canadian postal fallback: first letter, X split by FSA #}
{%- do cases.extend([
    (None, 'A1A 1A1', None, None, 'NL', 'NL'),
    (None, 'B3H 1A1', None, None, 'NS', 'NS'),
    (None, 'C1A 1A1', None, None, 'PE', 'PE'),
    (None, 'E1A 1A1', None, None, 'NB', 'NB'),
    (None, 'G1A 1A1', None, None, 'QC', 'QC'),
    (None, 'H2X 1Y4', None, None, 'QC', 'QC'),
    (None, 'J8X 1A1', None, None, 'QC', 'QC'),
    (None, 'K1A 0B1', None, None, 'ON', 'ON'),
    (None, 'L5B 1A1', None, None, 'ON', 'ON'),
    (None, 'M5V 3A8', None, None, 'ON', 'ON'),
    (None, 'N2L 3G1', None, None, 'ON', 'ON'),
    (None, 'P3A 1A1', None, None, 'ON', 'ON'),
    (None, 'R3C 1A1', None, None, 'MB', 'MB'),
    (None, 'S4P 1A1', None, None, 'SK', 'SK'),
    (None, 'T2P 1A1', None, None, 'AB', 'AB'),
    (None, 'V6B 1A1', None, None, 'BC', 'BC'),
    (None, 'Y1A 1A1', None, None, 'YT', 'YT'),
    (None, 'X0A 0H0', None, None, 'NU', 'NU'),
    (None, 'X0B 1B0', None, None, 'NU', 'NU'),
    (None, 'X0C 0A0', None, None, 'NU', 'NU'),
    (None, 'X0E 0N0', None, None, 'NT', 'NT'),
    (None, 'X1A 2P1', None, None, 'NT', 'NT'),
]) -%}

{# US ZIP fallback, including every prefix corrected relative to format_state #}
{%- do cases.extend([
    (None, '90210', None, None, 'CA', 'CA'),
    (None, '96799', None, None, 'AS', 'AS'),
    (None, '96813', None, None, 'HI', 'HI'),
    (None, '96950', None, None, 'MP', 'MP'),
    (None, '96952', None, None, 'MP', 'MP'),
    (None, '96910', None, None, 'GU', 'GU'),
    (None, '00802', None, None, 'VI', 'VI'),
    (None, '00901', None, None, 'PR', 'PR'),
    (None, '20201', None, None, 'DC', 'DC'),
    (None, '20166', None, None, 'VA', 'VA'),
    (None, '75701', None, None, 'TX', 'TX'),
    (None, '71601', None, None, 'AR', 'AR'),
    (None, '00501', None, None, 'NY', 'NY'),
    (None, '05501', None, None, 'MA', 'MA'),
    (None, '05401', None, None, 'VT', 'VT'),
    (None, '34001', None, None, None, None),
    (None, '33101', None, None, 'FL', 'FL'),
    (None, '2134',  None, None, 'MA', 'MA'),
    (None, 'garbage', None, None, None, None),
]) -%}

{# The name wins over the postal code #}
{%- do cases.extend([
    ('NY', '90210',   None, 'NY', 'NY', 'NY'),
    ('',   'M5V 3A8', None, None, 'ON', 'ON'),
]) -%}

{# Country restricts the result #}
{%- do cases.extend([
    ('BC',      None,      'Mexico', 'BC', 'BC', None),
    ('BC',      None,      'Canada', 'BC', 'BC', 'BC'),
    ('ON',      None,      'US',     'ON', 'ON', None),
    ('Ontario', '90210',   'US',     'ON', 'ON', 'CA'),
    (None,      'M5V 3A8', 'US',     None, 'ON', None),
    (None,      '90210',   'Narnia', None, 'CA', 'CA'),
]) -%}

with cases as (
    {{ case_rows(['state', 'postal', 'country', 'expected_state_only', 'expected_with_postal', 'expected_with_country'], cases) }}
)

select
    *,
    {{ dbt_dataloft.format_state_province('state') }} as actual_state_only,
    {{ dbt_dataloft.format_state_province('state', 'postal') }} as actual_with_postal,
    {{ dbt_dataloft.format_state_province('state', 'postal', 'country') }} as actual_with_country
from cases
