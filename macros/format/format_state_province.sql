{#
    Normalise a US state or Canadian province/territory to its two-letter code, with an
    optional postal-code fallback.

    US names and codes are matched by `format_state` (called without its ZIP argument);
    Canadian ones by the list below, in English and French, accented or not ('Québec',
    'Quebec', 'QC', and the retired 'PQ' and 'NF'). The two code sets do not collide, so
    one output column is safe.

    The name wins: the postal code is consulted only when the state value is null or
    unrecognised, the same precedence as `format_state`. The postal code goes through
    `format_postal` first, so a US ZIP that lost its leading zero is restored before its
    prefix is read -- `format_state` reads the raw value and gets those wrong.

    Postal fallback:
      Canada -- the first letter of the postal code names the province (Canada Post's
                FSA districts), except X, which is shared: X0A, X0B and X0C are Nunavut,
                every other X is the Northwest Territories.
      US     -- three-digit ZIP prefix ranges, checked most-specific-first. This
                deliberately DIFFERS from `format_state`'s fallback, which returns the
                wrong code for these prefixes (decided 2026-10-04 -- correct output over
                matching the original):
                    96799            AS  (format_state: HI)
                    96950-96952      MP  (format_state: GU)
                    008              VI  (format_state: PR)
                    202-205          DC  (format_state: VA)
                    755-759          TX  (format_state: AR)
                    005              NY  (format_state: null)
                    055              MA  (format_state: VT)
                    340              null -- Armed Forces Americas, not a state
                                         (format_state: FL)
                Known gap: Palau, the Marshall Islands and Micronesia also have 969xx
                ZIPs and come back as GU.

    `country_field`, if given, goes through `format_country` and restricts the result:
    US returns only a US code, CA only a Canadian one, any other recognised country null
    -- so Mexico's 'BC' (Baja California) is not read as British Columbia. A null or
    unrecognised country restricts nothing.

    Usage:
        {{ dbt_dataloft.format_state_province('state') }}
        {{ dbt_dataloft.format_state_province('state', 'postal_code') }}
        {{ dbt_dataloft.format_state_province('state', 'postal_code', 'country') }}
#}
{% macro format_state_province(state_field, postal_field=None, country_field=None) %}
    {%- set _stripped = dbt_dataloft.regex_replace_all("TRANSLATE(" ~ state_field ~ ", '.,-/_', '')", '[[:space:]]+', '') -%}
    {%- set cleaned_state = "UPPER(TRIM(" ~ _stripped ~ "))" -%}

    {%- set us_state = dbt_dataloft.format_state(state_field) -%}

    {%- set ca_province -%}
    case
        when {{ cleaned_state }} in ('ALBERTA', 'ALTA', 'AB') then 'AB'
        when {{ cleaned_state }} in ('BRITISHCOLUMBIA', 'COLOMBIEBRITANNIQUE', 'BC') then 'BC'
        when {{ cleaned_state }} in ('MANITOBA', 'MB') then 'MB'
        when {{ cleaned_state }} in ('NEWBRUNSWICK', 'NOUVEAUBRUNSWICK', 'NB') then 'NB'
        when {{ cleaned_state }} in ('NEWFOUNDLANDANDLABRADOR', 'NEWFOUNDLAND&LABRADOR', 'NEWFOUNDLAND', 'TERRENEUVEETLABRADOR', 'NL', 'NF') then 'NL'
        when {{ cleaned_state }} in ('NOVASCOTIA', 'NOUVELLEÉCOSSE', 'NOUVELLEECOSSE', 'NS') then 'NS'
        when {{ cleaned_state }} in ('NORTHWESTTERRITORIES', 'TERRITOIRESDUNORDOUEST', 'NWT', 'NT') then 'NT'
        when {{ cleaned_state }} in ('NUNAVUT', 'NU') then 'NU'
        when {{ cleaned_state }} in ('ONTARIO', 'ONT', 'ON') then 'ON'
        when {{ cleaned_state }} in ('PRINCEEDWARDISLAND', 'ÎLEDUPRINCEÉDOUARD', 'ILEDUPRINCEEDOUARD', 'PEI', 'PE') then 'PE'
        when {{ cleaned_state }} in ('QUEBEC', 'QUÉBEC', 'QUE', 'PQ', 'QC') then 'QC'
        when {{ cleaned_state }} in ('SASKATCHEWAN', 'SASK', 'SK') then 'SK'
        when {{ cleaned_state }} in ('YUKON', 'YUKONTERRITORY', 'YT') then 'YT'
        else null
    end
    {%- endset -%}

    {%- if postal_field is not none -%}
    {%- set postal = dbt_dataloft.format_postal(postal_field) -%}

    {#-- `postal` is either five digits or 'A1A 1A1', so the digit ranges below can never
         match a Canadian code and the letter checks can never match a US one. --#}
    {#-- US ZIP prefix ranges, FIRST MATCH WINS -- exceptions sit before the ranges that
         contain them. Expanded below into one `when '<prefix>'` per three-digit prefix,
         so the cleaned postal expression is written once rather than once per range:
         it is ~40 lines of SQL itself, and a `when ... between` per range pasted it
         ~95 times (6,500 compiled lines per call). A null code claims the prefix for
         nothing, so later ranges cannot. --#}
    {%- set us_prefix_ranges = [
        ('005', '005', 'NY'),  ('008', '008', 'VI'),  ('055', '055', 'MA'),  ('340', '340', none),
        ('350', '369', 'AL'),  ('995', '999', 'AK'),  ('850', '865', 'AZ'),  ('716', '729', 'AR'),
        ('900', '961', 'CA'),  ('800', '816', 'CO'),  ('060', '069', 'CT'),  ('197', '199', 'DE'),
        ('320', '349', 'FL'),  ('300', '319', 'GA'),  ('398', '399', 'GA'),  ('967', '968', 'HI'),
        ('832', '838', 'ID'),  ('600', '629', 'IL'),  ('460', '479', 'IN'),  ('500', '528', 'IA'),
        ('660', '679', 'KS'),  ('400', '427', 'KY'),  ('700', '714', 'LA'),  ('039', '049', 'ME'),
        ('206', '219', 'MD'),  ('010', '027', 'MA'),  ('480', '499', 'MI'),  ('550', '567', 'MN'),
        ('386', '397', 'MS'),  ('630', '658', 'MO'),  ('590', '599', 'MT'),  ('680', '693', 'NE'),
        ('889', '898', 'NV'),  ('030', '038', 'NH'),  ('070', '089', 'NJ'),  ('870', '884', 'NM'),
        ('100', '149', 'NY'),  ('270', '289', 'NC'),  ('580', '588', 'ND'),  ('430', '459', 'OH'),
        ('730', '741', 'OK'),  ('743', '749', 'OK'),  ('970', '979', 'OR'),  ('150', '196', 'PA'),
        ('028', '029', 'RI'),  ('290', '299', 'SC'),  ('570', '577', 'SD'),  ('370', '385', 'TN'),
        ('750', '799', 'TX'),  ('885', '888', 'TX'),  ('840', '847', 'UT'),  ('050', '059', 'VT'),
        ('201', '201', 'VA'),  ('220', '246', 'VA'),  ('980', '994', 'WA'),  ('247', '269', 'WV'),
        ('530', '549', 'WI'),  ('820', '831', 'WY'),  ('200', '200', 'DC'),  ('202', '205', 'DC'),
        ('569', '569', 'DC'),  ('006', '009', 'PR'),  ('969', '969', 'GU'),
    ] -%}
    {%- set us_prefix_codes = {} -%}
    {%- for lo, hi, code in us_prefix_ranges -%}
        {%- for n in range(lo | int, (hi | int) + 1) -%}
            {%- set prefix = '%03d' % n -%}
            {%- if prefix not in us_prefix_codes -%}
                {%- do us_prefix_codes.update({prefix: code}) -%}
            {%- endif -%}
        {%- endfor -%}
    {%- endfor -%}

    {#-- `postal` is either five digits or 'A1A 1A1', so a digit prefix can never match a
         Canadian code and a letter can never match a US one. --#}
    {%- set us_from_postal -%}
    case {{ postal }}
        -- Five-digit exceptions inside larger prefixes
        when '96799' then 'AS'
        when '96950' then 'MP'
        when '96951' then 'MP'
        when '96952' then 'MP'
        else case left({{ postal }}, 3)
            {%- for prefix in us_prefix_codes | sort %}
            {%- if us_prefix_codes[prefix] is not none %}
            when '{{ prefix }}' then '{{ us_prefix_codes[prefix] }}'
            {%- endif %}
            {%- endfor %}
            else null
        end
    end
    {%- endset -%}

    {%- set ca_from_postal -%}
    case left({{ postal }}, 1)
        when 'A' then 'NL'
        when 'B' then 'NS'
        when 'C' then 'PE'
        when 'E' then 'NB'
        when 'G' then 'QC'
        when 'H' then 'QC'
        when 'J' then 'QC'
        when 'K' then 'ON'
        when 'L' then 'ON'
        when 'M' then 'ON'
        when 'N' then 'ON'
        when 'P' then 'ON'
        when 'R' then 'MB'
        when 'S' then 'SK'
        when 'T' then 'AB'
        when 'V' then 'BC'
        when 'Y' then 'YT'
        -- X is split between two territories by the first three characters
        when 'X' then case left({{ postal }}, 3)
            when 'X0A' then 'NU'
            when 'X0B' then 'NU'
            when 'X0C' then 'NU'
            else 'NT'
        end
        else null
    end
    {%- endset -%}
    {%- else -%}
    {%- set us_from_postal = 'null' -%}
    {%- set ca_from_postal = 'null' -%}
    {%- endif -%}

    {% if country_field is none %}
    coalesce({{ us_state }}, {{ ca_province }}, {{ us_from_postal }}, {{ ca_from_postal }})
    {% else %}
    case coalesce({{ dbt_dataloft.format_country(country_field) }}, '??')
        when 'US' then coalesce({{ us_state }}, {{ us_from_postal }})
        when 'CA' then coalesce({{ ca_province }}, {{ ca_from_postal }})
        -- Country null or unrecognised: no restriction
        when '??' then coalesce({{ us_state }}, {{ ca_province }}, {{ us_from_postal }}, {{ ca_from_postal }})
        -- A recognised country other than US or CA
        else null
    end
    {% endif %}
{% endmacro %}
