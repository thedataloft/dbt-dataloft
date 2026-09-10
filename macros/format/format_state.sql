{#
    Normalise a US state to its two-letter code, with an optional ZIP fallback.

    Ported from the originating client project's `generate_formated_state`. Lookup logic preserved verbatim,
    INCLUDING the known dead branches below. Two edits only: whitespace stripping now
    goes through the dialect shim using POSIX `[[:space:]]+`, because the original's
    rendered '\\s+' silently fails to match on DuckDB (no error -- whitespace simply
    survives); `translate` is unchanged, having been verified to work on both.

    KNOWN DEAD BRANCHES (carried over deliberately, 2026-08-13). In the ZIP fallback,
    earlier `between` ranges swallow three later cases, so these can never be returned:
        '967' -> AS   is caught by   between '967' and '968' -> HI
        '969' -> MP   is caught by   '969' -> GU
        '008' -> VI   is caught by   between '006' and '009' -> PR
    American Samoa, the Northern Mariana Islands and the US Virgin Islands are
    therefore unreachable from a ZIP. Left as-is to match the original rather than silently
    diverge. Fixing requires reordering the branches most-specific-first.

    Usage:
        {{ dbt_dataloft.format_state('state') }}
        {{ dbt_dataloft.format_state('state', 'postal_code') }}
#}
{% macro format_state(state_field, zip_code_field=None) %}
    {%- set _stripped = dbt_dataloft.regex_replace_all("TRANSLATE(" ~ state_field ~ ", '.,-/_', '')", '[[:space:]]+', '') -%}
    {%- set cleaned_state = "UPPER(TRIM(" ~ _stripped ~ "))" -%}
    {% if zip_code_field is not none %}
    {% set cleaned_zip = "trim(replace(replace(replace(replace(" ~ zip_code_field ~ ", '-', ''), ' ', ''), '.', ''), '+', ''))" %}
    {% endif %}
    
    case
        -- Alabama
        when {{ cleaned_state }} in ('ALABAMA', 'AL') then 'AL'
        -- Alaska
        when {{ cleaned_state }} in ('ALASKA', 'AK') then 'AK'
        -- Arizona
        when {{ cleaned_state }} in ('ARIZONA', 'AZ') then 'AZ'
        -- Arkansas
        when {{ cleaned_state }} in ('ARKANSAS', 'AR') then 'AR'
        -- California
        when {{ cleaned_state }} in ('CALIFORNIA', 'CA') then 'CA'
        -- Colorado
        when {{ cleaned_state }} in ('COLORADO', 'CO') then 'CO'
        -- Connecticut
        when {{ cleaned_state }} in ('CONNECTICUT', 'CT') then 'CT'
        -- Delaware
        when {{ cleaned_state }} in ('DELAWARE', 'DE') then 'DE'
        -- Florida
        when {{ cleaned_state }} in ('FLORIDA', 'FL') then 'FL'
        -- Georgia
        when {{ cleaned_state }} in ('GEORGIA', 'GA') then 'GA'
        -- Hawaii
        when {{ cleaned_state }} in ('HAWAII', 'HI') then 'HI'
        -- Idaho
        when {{ cleaned_state }} in ('IDAHO', 'ID') then 'ID'
        -- Illinois
        when {{ cleaned_state }} in ('ILLINOIS', 'IL') then 'IL'
        -- Indiana
        when {{ cleaned_state }} in ('INDIANA', 'IN') then 'IN'
        -- Iowa
        when {{ cleaned_state }} in ('IOWA', 'IA') then 'IA'
        -- Kansas
        when {{ cleaned_state }} in ('KANSAS', 'KS') then 'KS'
        -- Kentucky
        when {{ cleaned_state }} in ('KENTUCKY', 'KY') then 'KY'
        -- Louisiana
        when {{ cleaned_state }} in ('LOUISIANA', 'LA') then 'LA'
        -- Maine
        when {{ cleaned_state }} in ('MAINE', 'ME') then 'ME'
        -- Maryland
        when {{ cleaned_state }} in ('MARYLAND', 'MD') then 'MD'
        -- Massachusetts
        when {{ cleaned_state }} in ('MASSACHUSETTS', 'MA') then 'MA'
        -- Michigan
        when {{ cleaned_state }} in ('MICHIGAN', 'MI') then 'MI'
        -- Minnesota
        when {{ cleaned_state }} in ('MINNESOTA', 'MN') then 'MN'
        -- Mississippi
        when {{ cleaned_state }} in ('MISSISSIPPI', 'MS') then 'MS'
        -- Missouri
        when {{ cleaned_state }} in ('MISSOURI', 'MO') then 'MO'
        -- Montana
        when {{ cleaned_state }} in ('MONTANA', 'MT') then 'MT'
        -- Nebraska
        when {{ cleaned_state }} in ('NEBRASKA', 'NE') then 'NE'
        -- Nevada
        when {{ cleaned_state }} in ('NEVADA', 'NV') then 'NV'
        -- New Hampshire
        when {{ cleaned_state }} in ('NEWHAMPSHIRE', 'NH') then 'NH'
        -- New Jersey
        when {{ cleaned_state }} in ('NEWJERSEY', 'NJ') then 'NJ'
        -- New Mexico
        when {{ cleaned_state }} in ('NEWMEXICO', 'NM') then 'NM'
        -- New York
        when {{ cleaned_state }} in ('NEWYORK', 'NY') then 'NY'
        -- North Carolina
        when {{ cleaned_state }} in ('NORTHCAROLINA', 'NC') then 'NC'
        -- North Dakota
        when {{ cleaned_state }} in ('NORTHDAKOTA', 'ND') then 'ND'
        -- Ohio
        when {{ cleaned_state }} in ('OHIO', 'OH') then 'OH'
        -- Oklahoma
        when {{ cleaned_state }} in ('OKLAHOMA', 'OK') then 'OK'
        -- Oregon
        when {{ cleaned_state }} in ('OREGON', 'OR') then 'OR'
        -- Pennsylvania
        when {{ cleaned_state }} in ('PENNSYLVANIA', 'PA') then 'PA'
        -- Rhode Island
        when {{ cleaned_state }} in ('RHODEISLAND', 'RI') then 'RI'
        -- South Carolina
        when {{ cleaned_state }} in ('SOUTHCAROLINA', 'SC') then 'SC'
        -- South Dakota
        when {{ cleaned_state }} in ('SOUTHDAKOTA', 'SD') then 'SD'
        -- Tennessee
        when {{ cleaned_state }} in ('TENNESSEE', 'TN') then 'TN'
        -- Texas
        when {{ cleaned_state }} in ('TEXAS', 'TX') then 'TX'
        -- Utah
        when {{ cleaned_state }} in ('UTAH', 'UT') then 'UT'
        -- Vermont
        when {{ cleaned_state }} in ('VERMONT', 'VT') then 'VT'
        -- Virginia
        when {{ cleaned_state }} in ('VIRGINIA', 'VA') then 'VA'
        -- Washington
        when {{ cleaned_state }} in ('WASHINGTON', 'WA') then 'WA'
        -- West Virginia
        when {{ cleaned_state }} in ('WESTVIRGINIA', 'WV') then 'WV'
        -- Wisconsin
        when {{ cleaned_state }} in ('WISCONSIN', 'WI') then 'WI'
        -- Wyoming
        when {{ cleaned_state }} in ('WYOMING', 'WY') then 'WY'
        
        -- District of Columbia
        when {{ cleaned_state }} in ('DISTRICTOFCOLUMBIA', 'DC', 'WASHINGTONDC') then 'DC'
        
        -- Territories
        when {{ cleaned_state }} in ('PUERTORICO', 'PR') then 'PR'
        when {{ cleaned_state }} in ('VIRGINISLANDS', 'USVIRGINISLANDS', 'VI') then 'VI'
        when {{ cleaned_state }} in ('GUAM', 'GU') then 'GU'
        when {{ cleaned_state }} in ('AMERICANSAMOA', 'AS') then 'AS'
        when {{ cleaned_state }} in ('NORTHERNMARIANAISLANDS', 'MP') then 'MP'
        
        {% if zip_code_field is not none %}
        -- Fallback to zip code ranges if state doesn't match
        -- Alabama (350-369)
        when left({{ cleaned_zip }}, 3) between '350' and '369' then 'AL'
        -- Alaska (995-999)
        when left({{ cleaned_zip }}, 3) between '995' and '999' then 'AK'
        -- Arizona (850-865)
        when left({{ cleaned_zip }}, 3) between '850' and '865' then 'AZ'
        -- Arkansas (716-729, 755-759)
        when left({{ cleaned_zip }}, 3) between '716' and '729' then 'AR'
        when left({{ cleaned_zip }}, 3) between '755' and '759' then 'AR'
        -- California (900-961)
        when left({{ cleaned_zip }}, 3) between '900' and '961' then 'CA'
        -- Colorado (800-816)
        when left({{ cleaned_zip }}, 3) between '800' and '816' then 'CO'
        -- Connecticut (060-069)
        when left({{ cleaned_zip }}, 3) between '060' and '069' then 'CT'
        -- Delaware (197-199)
        when left({{ cleaned_zip }}, 3) between '197' and '199' then 'DE'
        -- Florida (320-349)
        when left({{ cleaned_zip }}, 3) between '320' and '349' then 'FL'
        -- Georgia (300-319, 398-399)
        when left({{ cleaned_zip }}, 3) between '300' and '319' then 'GA'
        when left({{ cleaned_zip }}, 3) between '398' and '399' then 'GA'
        -- Hawaii (967-968)
        when left({{ cleaned_zip }}, 3) between '967' and '968' then 'HI'
        -- Idaho (832-838)
        when left({{ cleaned_zip }}, 3) between '832' and '838' then 'ID'
        -- Illinois (600-629)
        when left({{ cleaned_zip }}, 3) between '600' and '629' then 'IL'
        -- Indiana (460-479)
        when left({{ cleaned_zip }}, 3) between '460' and '479' then 'IN'
        -- Iowa (500-528)
        when left({{ cleaned_zip }}, 3) between '500' and '528' then 'IA'
        -- Kansas (660-679)
        when left({{ cleaned_zip }}, 3) between '660' and '679' then 'KS'
        -- Kentucky (400-427)
        when left({{ cleaned_zip }}, 3) between '400' and '427' then 'KY'
        -- Louisiana (700-714)
        when left({{ cleaned_zip }}, 3) between '700' and '714' then 'LA'
        -- Maine (039-049)
        when left({{ cleaned_zip }}, 3) between '039' and '049' then 'ME'
        -- Maryland (206-219)
        when left({{ cleaned_zip }}, 3) between '206' and '219' then 'MD'
        -- Massachusetts (010-027)
        when left({{ cleaned_zip }}, 3) between '010' and '027' then 'MA'
        -- Michigan (480-499)
        when left({{ cleaned_zip }}, 3) between '480' and '499' then 'MI'
        -- Minnesota (550-567)
        when left({{ cleaned_zip }}, 3) between '550' and '567' then 'MN'
        -- Mississippi (386-397)
        when left({{ cleaned_zip }}, 3) between '386' and '397' then 'MS'
        -- Missouri (630-658)
        when left({{ cleaned_zip }}, 3) between '630' and '658' then 'MO'
        -- Montana (590-599)
        when left({{ cleaned_zip }}, 3) between '590' and '599' then 'MT'
        -- Nebraska (680-693)
        when left({{ cleaned_zip }}, 3) between '680' and '693' then 'NE'
        -- Nevada (889-898)
        when left({{ cleaned_zip }}, 3) between '889' and '898' then 'NV'
        -- New Hampshire (030-038)
        when left({{ cleaned_zip }}, 3) between '030' and '038' then 'NH'
        -- New Jersey (070-089)
        when left({{ cleaned_zip }}, 3) between '070' and '089' then 'NJ'
        -- New Mexico (870-884)
        when left({{ cleaned_zip }}, 3) between '870' and '884' then 'NM'
        -- New York (100-149)
        when left({{ cleaned_zip }}, 3) between '100' and '149' then 'NY'
        -- North Carolina (270-289)
        when left({{ cleaned_zip }}, 3) between '270' and '289' then 'NC'
        -- North Dakota (580-588)
        when left({{ cleaned_zip }}, 3) between '580' and '588' then 'ND'
        -- Ohio (430-459)
        when left({{ cleaned_zip }}, 3) between '430' and '459' then 'OH'
        -- Oklahoma (730-741, 743-749)
        when left({{ cleaned_zip }}, 3) between '730' and '741' then 'OK'
        when left({{ cleaned_zip }}, 3) between '743' and '749' then 'OK'
        -- Oregon (970-979)
        when left({{ cleaned_zip }}, 3) between '970' and '979' then 'OR'
        -- Pennsylvania (150-196)
        when left({{ cleaned_zip }}, 3) between '150' and '196' then 'PA'
        -- Rhode Island (028-029)
        when left({{ cleaned_zip }}, 3) between '028' and '029' then 'RI'
        -- South Carolina (290-299)
        when left({{ cleaned_zip }}, 3) between '290' and '299' then 'SC'
        -- South Dakota (570-577)
        when left({{ cleaned_zip }}, 3) between '570' and '577' then 'SD'
        -- Tennessee (370-385)
        when left({{ cleaned_zip }}, 3) between '370' and '385' then 'TN'
        -- Texas (750-754, 760-799, 885-888)
        when left({{ cleaned_zip }}, 3) between '750' and '754' then 'TX'
        when left({{ cleaned_zip }}, 3) between '760' and '799' then 'TX'
        when left({{ cleaned_zip }}, 3) between '885' and '888' then 'TX'
        -- Utah (840-847)
        when left({{ cleaned_zip }}, 3) between '840' and '847' then 'UT'
        -- Vermont (050-059)
        when left({{ cleaned_zip }}, 3) between '050' and '059' then 'VT'
        -- Virginia (201-205, 220-246)
        when left({{ cleaned_zip }}, 3) between '201' and '205' then 'VA'
        when left({{ cleaned_zip }}, 3) between '220' and '246' then 'VA'
        -- Washington (980-994)
        when left({{ cleaned_zip }}, 3) between '980' and '994' then 'WA'
        -- West Virginia (247-269)
        when left({{ cleaned_zip }}, 3) between '247' and '269' then 'WV'
        -- Wisconsin (530-549)
        when left({{ cleaned_zip }}, 3) between '530' and '549' then 'WI'
        -- Wyoming (820-831)
        when left({{ cleaned_zip }}, 3) between '820' and '831' then 'WY'
        
        -- District of Columbia (200, 202-205, 569)
        when left({{ cleaned_zip }}, 3) = '200' then 'DC'
        when left({{ cleaned_zip }}, 3) between '202' and '205' then 'DC'
        when left({{ cleaned_zip }}, 3) = '569' then 'DC'
        
        -- Territories
        -- Puerto Rico (006-009)
        when left({{ cleaned_zip }}, 3) between '006' and '009' then 'PR'
        -- Virgin Islands (008)
        when left({{ cleaned_zip }}, 3) = '008' then 'VI'
        -- Guam (969)
        when left({{ cleaned_zip }}, 3) = '969' then 'GU'
        -- American Samoa (967)
        when left({{ cleaned_zip }}, 3) = '967' then 'AS'
        -- Northern Mariana Islands (969)
        when left({{ cleaned_zip }}, 3) = '969' then 'MP'
        {% endif %}
        
        -- Return null if no match
        else null
    end
{% endmacro %}

