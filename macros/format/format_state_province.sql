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
    {%- set us_from_postal -%}
    case
        -- Five-digit exceptions inside larger ranges -- must precede them
        -- American Samoa (96799, inside Hawaii's 967)
        when {{ postal }} = '96799' then 'AS'
        -- Northern Mariana Islands (96950-96952, inside Guam's 969)
        when {{ postal }} between '96950' and '96952' then 'MP'

        -- Three-digit exceptions inside larger ranges -- must precede them
        -- Holtsville, NY IRS (005)
        when left({{ postal }}, 3) = '005' then 'NY'
        -- US Virgin Islands (008, inside Puerto Rico's 006-009)
        when left({{ postal }}, 3) = '008' then 'VI'
        -- Andover, MA IRS (055, inside Vermont's 050-059)
        when left({{ postal }}, 3) = '055' then 'MA'
        -- Armed Forces Americas (340, inside Florida's 320-349) -- not a state
        when left({{ postal }}, 3) = '340' then null

        -- Alabama (350-369)
        when left({{ postal }}, 3) between '350' and '369' then 'AL'
        -- Alaska (995-999)
        when left({{ postal }}, 3) between '995' and '999' then 'AK'
        -- Arizona (850-865)
        when left({{ postal }}, 3) between '850' and '865' then 'AZ'
        -- Arkansas (716-729)
        when left({{ postal }}, 3) between '716' and '729' then 'AR'
        -- California (900-961)
        when left({{ postal }}, 3) between '900' and '961' then 'CA'
        -- Colorado (800-816)
        when left({{ postal }}, 3) between '800' and '816' then 'CO'
        -- Connecticut (060-069)
        when left({{ postal }}, 3) between '060' and '069' then 'CT'
        -- Delaware (197-199)
        when left({{ postal }}, 3) between '197' and '199' then 'DE'
        -- Florida (320-349)
        when left({{ postal }}, 3) between '320' and '349' then 'FL'
        -- Georgia (300-319, 398-399)
        when left({{ postal }}, 3) between '300' and '319' then 'GA'
        when left({{ postal }}, 3) between '398' and '399' then 'GA'
        -- Hawaii (967-968)
        when left({{ postal }}, 3) between '967' and '968' then 'HI'
        -- Idaho (832-838)
        when left({{ postal }}, 3) between '832' and '838' then 'ID'
        -- Illinois (600-629)
        when left({{ postal }}, 3) between '600' and '629' then 'IL'
        -- Indiana (460-479)
        when left({{ postal }}, 3) between '460' and '479' then 'IN'
        -- Iowa (500-528)
        when left({{ postal }}, 3) between '500' and '528' then 'IA'
        -- Kansas (660-679)
        when left({{ postal }}, 3) between '660' and '679' then 'KS'
        -- Kentucky (400-427)
        when left({{ postal }}, 3) between '400' and '427' then 'KY'
        -- Louisiana (700-714)
        when left({{ postal }}, 3) between '700' and '714' then 'LA'
        -- Maine (039-049)
        when left({{ postal }}, 3) between '039' and '049' then 'ME'
        -- Maryland (206-219)
        when left({{ postal }}, 3) between '206' and '219' then 'MD'
        -- Massachusetts (010-027)
        when left({{ postal }}, 3) between '010' and '027' then 'MA'
        -- Michigan (480-499)
        when left({{ postal }}, 3) between '480' and '499' then 'MI'
        -- Minnesota (550-567)
        when left({{ postal }}, 3) between '550' and '567' then 'MN'
        -- Mississippi (386-397)
        when left({{ postal }}, 3) between '386' and '397' then 'MS'
        -- Missouri (630-658)
        when left({{ postal }}, 3) between '630' and '658' then 'MO'
        -- Montana (590-599)
        when left({{ postal }}, 3) between '590' and '599' then 'MT'
        -- Nebraska (680-693)
        when left({{ postal }}, 3) between '680' and '693' then 'NE'
        -- Nevada (889-898)
        when left({{ postal }}, 3) between '889' and '898' then 'NV'
        -- New Hampshire (030-038)
        when left({{ postal }}, 3) between '030' and '038' then 'NH'
        -- New Jersey (070-089)
        when left({{ postal }}, 3) between '070' and '089' then 'NJ'
        -- New Mexico (870-884)
        when left({{ postal }}, 3) between '870' and '884' then 'NM'
        -- New York (100-149)
        when left({{ postal }}, 3) between '100' and '149' then 'NY'
        -- North Carolina (270-289)
        when left({{ postal }}, 3) between '270' and '289' then 'NC'
        -- North Dakota (580-588)
        when left({{ postal }}, 3) between '580' and '588' then 'ND'
        -- Ohio (430-459)
        when left({{ postal }}, 3) between '430' and '459' then 'OH'
        -- Oklahoma (730-741, 743-749)
        when left({{ postal }}, 3) between '730' and '741' then 'OK'
        when left({{ postal }}, 3) between '743' and '749' then 'OK'
        -- Oregon (970-979)
        when left({{ postal }}, 3) between '970' and '979' then 'OR'
        -- Pennsylvania (150-196)
        when left({{ postal }}, 3) between '150' and '196' then 'PA'
        -- Rhode Island (028-029)
        when left({{ postal }}, 3) between '028' and '029' then 'RI'
        -- South Carolina (290-299)
        when left({{ postal }}, 3) between '290' and '299' then 'SC'
        -- South Dakota (570-577)
        when left({{ postal }}, 3) between '570' and '577' then 'SD'
        -- Tennessee (370-385)
        when left({{ postal }}, 3) between '370' and '385' then 'TN'
        -- Texas (750-799, 885-888) -- 755-759 is East Texas (Texarkana TX, Tyler, Longview)
        when left({{ postal }}, 3) between '750' and '799' then 'TX'
        when left({{ postal }}, 3) between '885' and '888' then 'TX'
        -- Utah (840-847)
        when left({{ postal }}, 3) between '840' and '847' then 'UT'
        -- Vermont (050-059, less 055 above)
        when left({{ postal }}, 3) between '050' and '059' then 'VT'
        -- Virginia (201, 220-246) -- 202-205 is DC, below
        when left({{ postal }}, 3) = '201' then 'VA'
        when left({{ postal }}, 3) between '220' and '246' then 'VA'
        -- Washington (980-994)
        when left({{ postal }}, 3) between '980' and '994' then 'WA'
        -- West Virginia (247-269)
        when left({{ postal }}, 3) between '247' and '269' then 'WV'
        -- Wisconsin (530-549)
        when left({{ postal }}, 3) between '530' and '549' then 'WI'
        -- Wyoming (820-831)
        when left({{ postal }}, 3) between '820' and '831' then 'WY'

        -- District of Columbia (200, 202-205, 569)
        when left({{ postal }}, 3) = '200' then 'DC'
        when left({{ postal }}, 3) between '202' and '205' then 'DC'
        when left({{ postal }}, 3) = '569' then 'DC'

        -- Territories (the exceptions above already took AS, MP and VI)
        -- Puerto Rico (006-009, less 008)
        when left({{ postal }}, 3) between '006' and '009' then 'PR'
        -- Guam (969, less 96950-96952)
        when left({{ postal }}, 3) = '969' then 'GU'

        else null
    end
    {%- endset -%}

    {%- set ca_from_postal -%}
    case
        -- X is split between two territories by the first three characters
        when left({{ postal }}, 3) in ('X0A', 'X0B', 'X0C') then 'NU'
        when left({{ postal }}, 1) = 'X' then 'NT'
        when left({{ postal }}, 1) = 'A' then 'NL'
        when left({{ postal }}, 1) = 'B' then 'NS'
        when left({{ postal }}, 1) = 'C' then 'PE'
        when left({{ postal }}, 1) = 'E' then 'NB'
        when left({{ postal }}, 1) in ('G', 'H', 'J') then 'QC'
        when left({{ postal }}, 1) in ('K', 'L', 'M', 'N', 'P') then 'ON'
        when left({{ postal }}, 1) = 'R' then 'MB'
        when left({{ postal }}, 1) = 'S' then 'SK'
        when left({{ postal }}, 1) = 'T' then 'AB'
        when left({{ postal }}, 1) = 'V' then 'BC'
        when left({{ postal }}, 1) = 'Y' then 'YT'
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
