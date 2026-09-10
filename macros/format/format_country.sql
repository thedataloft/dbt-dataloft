{#
    Normalise a country name to its ISO 3166-1 alpha-2 code.

    Ported from the originating client project's `generate_formated_country`. Lookup logic preserved verbatim.
    Single edit: whitespace stripping goes through the dialect shim using POSIX
    `[[:space:]]+`, because the original's rendered '\\s+' silently fails to match on
    DuckDB.

    Usage:
        {{ dbt_dataloft.format_country('country') }}
#}
{% macro format_country(country_field) %}
    {%- set _stripped = dbt_dataloft.regex_replace_all("TRANSLATE(" ~ country_field ~ ", '.,-/_', '')", '[[:space:]]+', '') -%}
    {%- set cleaned_country = "UPPER(TRIM(" ~ _stripped ~ "))" -%}
    
    case
        -- United States (priority, most common in dataset)
        when {{ cleaned_country }} in ('UNITEDSTATES', 'UNITEDSTATESOFAMERICA', 'USA', 'US', 'AMERICA') then 'US'

        -- North America
        when {{ cleaned_country }} in ('CANADA', 'CA') then 'CA'
        when {{ cleaned_country }} in ('MEXICO', 'MX') then 'MX'
        
        -- Central America & Caribbean
        when {{ cleaned_country }} in ('COSTARICA', 'CR') then 'CR'
        when {{ cleaned_country }} in ('CUBA', 'CU') then 'CU'
        when {{ cleaned_country }} in ('DOMINICANREPUBLIC', 'DO') then 'DO'
        when {{ cleaned_country }} in ('ELSALVADOR', 'SV') then 'SV'
        when {{ cleaned_country }} in ('GUATEMALA', 'GT') then 'GT'
        when {{ cleaned_country }} in ('HONDURAS', 'HN') then 'HN'
        when {{ cleaned_country }} in ('JAMAICA', 'JM') then 'JM'
        when {{ cleaned_country }} in ('NICARAGUA', 'NI') then 'NI'
        when {{ cleaned_country }} in ('PANAMA', 'PA') then 'PA'
        when {{ cleaned_country }} in ('PUERTORICO', 'PR') then 'PR'
        when {{ cleaned_country }} in ('TRINIDADANDTOBAGO', 'TT') then 'TT'
        
        -- South America
        when {{ cleaned_country }} in ('ARGENTINA', 'AR') then 'AR'
        when {{ cleaned_country }} in ('BOLIVIA', 'BO') then 'BO'
        when {{ cleaned_country }} in ('BRAZIL', 'BR') then 'BR'
        when {{ cleaned_country }} in ('CHILE', 'CL') then 'CL'
        when {{ cleaned_country }} in ('COLOMBIA', 'CO') then 'CO'
        when {{ cleaned_country }} in ('ECUADOR', 'EC') then 'EC'
        when {{ cleaned_country }} in ('GUYANA', 'GY') then 'GY'
        when {{ cleaned_country }} in ('PARAGUAY', 'PY') then 'PY'
        when {{ cleaned_country }} in ('PERU', 'PE') then 'PE'
        when {{ cleaned_country }} in ('SURINAME', 'SR') then 'SR'
        when {{ cleaned_country }} in ('URUGUAY', 'UY') then 'UY'
        when {{ cleaned_country }} in ('VENEZUELA', 'VE') then 'VE'
        
        -- Europe - Western
        when {{ cleaned_country }} in ('AUSTRIA', 'AT') then 'AT'
        when {{ cleaned_country }} in ('BELGIUM', 'BE') then 'BE'
        when {{ cleaned_country }} in ('FRANCE', 'FR') then 'FR'
        when {{ cleaned_country }} in ('GERMANY', 'DE') then 'DE'
        when {{ cleaned_country }} in ('IRELAND', 'IE') then 'IE'
        when {{ cleaned_country }} in ('LUXEMBOURG', 'LU') then 'LU'
        when {{ cleaned_country }} in ('MONACO', 'MC') then 'MC'
        when {{ cleaned_country }} in ('NETHERLANDS', 'NL') then 'NL'
        when {{ cleaned_country }} in ('SWITZERLAND', 'CH') then 'CH'
        when {{ cleaned_country }} in ('UNITEDKINGDOM', 'UK', 'GB', 'GREATBRITAIN', 'ENGLAND', 'SCOTLAND', 'WALES', 'NORTHERNIRELAND') then 'GB'
        
        -- Europe - Northern
        when {{ cleaned_country }} in ('DENMARK', 'DK') then 'DK'
        when {{ cleaned_country }} in ('ESTONIA', 'EE') then 'EE'
        when {{ cleaned_country }} in ('FINLAND', 'FI') then 'FI'
        when {{ cleaned_country }} in ('ICELAND', 'IS') then 'IS'
        when {{ cleaned_country }} in ('LATVIA', 'LV') then 'LV'
        when {{ cleaned_country }} in ('LITHUANIA', 'LT') then 'LT'
        when {{ cleaned_country }} in ('NORWAY', 'NO') then 'NO'
        when {{ cleaned_country }} in ('SWEDEN', 'SE') then 'SE'
        
        -- Europe - Southern
        when {{ cleaned_country }} in ('ALBANIA', 'AL') then 'AL'
        when {{ cleaned_country }} in ('CROATIA', 'HR') then 'HR'
        when {{ cleaned_country }} in ('GREECE', 'GR') then 'GR'
        when {{ cleaned_country }} in ('ITALY', 'IT') then 'IT'
        when {{ cleaned_country }} in ('MALTA', 'MT') then 'MT'
        when {{ cleaned_country }} in ('PORTUGAL', 'PT') then 'PT'
        when {{ cleaned_country }} in ('SLOVENIA', 'SI') then 'SI'
        when {{ cleaned_country }} in ('SPAIN', 'ES') then 'ES'
        
        -- Europe - Eastern
        when {{ cleaned_country }} in ('BELARUS', 'BY') then 'BY'
        when {{ cleaned_country }} in ('BOSNIAANDHERZEGOVINA', 'BA') then 'BA'
        when {{ cleaned_country }} in ('BULGARIA', 'BG') then 'BG'
        when {{ cleaned_country }} in ('CZECHREPUBLIC', 'CZECHIA', 'CZ') then 'CZ'
        when {{ cleaned_country }} in ('HUNGARY', 'HU') then 'HU'
        when {{ cleaned_country }} in ('MOLDOVA', 'MD') then 'MD'
        when {{ cleaned_country }} in ('POLAND', 'PL') then 'PL'
        when {{ cleaned_country }} in ('ROMANIA', 'RO') then 'RO'
        when {{ cleaned_country }} in ('RUSSIA', 'RUSSIANFEDERATION', 'RU') then 'RU'
        when {{ cleaned_country }} in ('SERBIA', 'RS') then 'RS'
        when {{ cleaned_country }} in ('SLOVAKIA', 'SK') then 'SK'
        when {{ cleaned_country }} in ('UKRAINE', 'UA') then 'UA'
        
        -- Asia - East
        when {{ cleaned_country }} in ('CHINA', 'CN') then 'CN'
        when {{ cleaned_country }} in ('HONGKONG', 'HK') then 'HK'
        when {{ cleaned_country }} in ('JAPAN', 'JP') then 'JP'
        when {{ cleaned_country }} in ('MACAU', 'MO') then 'MO'
        when {{ cleaned_country }} in ('MONGOLIA', 'MN') then 'MN'
        when {{ cleaned_country }} in ('NORTHKOREA', 'KP') then 'KP'
        when {{ cleaned_country }} in ('SOUTHKOREA', 'KOREA', 'KR') then 'KR'
        when {{ cleaned_country }} in ('TAIWAN', 'TW') then 'TW'
        
        -- Asia - Southeast
        when {{ cleaned_country }} in ('BRUNEI', 'BN') then 'BN'
        when {{ cleaned_country }} in ('CAMBODIA', 'KH') then 'KH'
        when {{ cleaned_country }} in ('INDONESIA', 'ID') then 'ID'
        when {{ cleaned_country }} in ('LAOS', 'LA') then 'LA'
        when {{ cleaned_country }} in ('MALAYSIA', 'MY') then 'MY'
        when {{ cleaned_country }} in ('MYANMAR', 'BURMA', 'MM') then 'MM'
        when {{ cleaned_country }} in ('PHILIPPINES', 'PH') then 'PH'
        when {{ cleaned_country }} in ('SINGAPORE', 'SG') then 'SG'
        when {{ cleaned_country }} in ('THAILAND', 'TH') then 'TH'
        when {{ cleaned_country }} in ('TIMORLESTE', 'EASTTIMOR', 'TL') then 'TL'
        when {{ cleaned_country }} in ('VIETNAM', 'VN') then 'VN'
        
        -- Asia - South
        when {{ cleaned_country }} in ('AFGHANISTAN', 'AF') then 'AF'
        when {{ cleaned_country }} in ('BANGLADESH', 'BD') then 'BD'
        when {{ cleaned_country }} in ('BHUTAN', 'BT') then 'BT'
        when {{ cleaned_country }} in ('INDIA', 'IN') then 'IN'
        when {{ cleaned_country }} in ('MALDIVES', 'MV') then 'MV'
        when {{ cleaned_country }} in ('NEPAL', 'NP') then 'NP'
        when {{ cleaned_country }} in ('PAKISTAN', 'PK') then 'PK'
        when {{ cleaned_country }} in ('SRILANKA', 'LK') then 'LK'
        
        -- Middle East
        when {{ cleaned_country }} in ('BAHRAIN', 'BH') then 'BH'
        when {{ cleaned_country }} in ('CYPRUS', 'CY') then 'CY'
        when {{ cleaned_country }} in ('EGYPT', 'EG') then 'EG'
        when {{ cleaned_country }} in ('IRAN', 'IR') then 'IR'
        when {{ cleaned_country }} in ('IRAQ', 'IQ') then 'IQ'
        when {{ cleaned_country }} in ('ISRAEL', 'IL') then 'IL'
        when {{ cleaned_country }} in ('JORDAN', 'JO') then 'JO'
        when {{ cleaned_country }} in ('KUWAIT', 'KW') then 'KW'
        when {{ cleaned_country }} in ('LEBANON', 'LB') then 'LB'
        when {{ cleaned_country }} in ('OMAN', 'OM') then 'OM'
        when {{ cleaned_country }} in ('PALESTINE', 'PS') then 'PS'
        when {{ cleaned_country }} in ('QATAR', 'QA') then 'QA'
        when {{ cleaned_country }} in ('SAUDIARABIA', 'SA') then 'SA'
        when {{ cleaned_country }} in ('SYRIA', 'SY') then 'SY'
        when {{ cleaned_country }} in ('TURKEY', 'TURKIYE', 'TR') then 'TR'
        when {{ cleaned_country }} in ('UNITEDARABEMIRATES', 'UAE', 'AE') then 'AE'
        when {{ cleaned_country }} in ('YEMEN', 'YE') then 'YE'
        
        -- Africa - North
        when {{ cleaned_country }} in ('ALGERIA', 'DZ') then 'DZ'
        when {{ cleaned_country }} in ('LIBYA', 'LY') then 'LY'
        when {{ cleaned_country }} in ('MOROCCO', 'MA') then 'MA'
        when {{ cleaned_country }} in ('SUDAN', 'SD') then 'SD'
        when {{ cleaned_country }} in ('TUNISIA', 'TN') then 'TN'
        
        -- Africa - West
        when {{ cleaned_country }} in ('BENIN', 'BJ') then 'BJ'
        when {{ cleaned_country }} in ('BURKINAFASO', 'BF') then 'BF'
        when {{ cleaned_country }} in ('CAMEROON', 'CM') then 'CM'
        when {{ cleaned_country }} in ('CHAD', 'TD') then 'TD'
        when {{ cleaned_country }} in ('COTEDIVOIRE', 'IVORYCOAST', 'CI') then 'CI'
        when {{ cleaned_country }} in ('GHANA', 'GH') then 'GH'
        when {{ cleaned_country }} in ('GUINEA', 'GN') then 'GN'
        when {{ cleaned_country }} in ('MALI', 'ML') then 'ML'
        when {{ cleaned_country }} in ('MAURITANIA', 'MR') then 'MR'
        when {{ cleaned_country }} in ('NIGER', 'NE') then 'NE'
        when {{ cleaned_country }} in ('NIGERIA', 'NG') then 'NG'
        when {{ cleaned_country }} in ('SENEGAL', 'SN') then 'SN'
        when {{ cleaned_country }} in ('TOGO', 'TG') then 'TG'
        
        -- Africa - East
        when {{ cleaned_country }} in ('ETHIOPIA', 'ET') then 'ET'
        when {{ cleaned_country }} in ('KENYA', 'KE') then 'KE'
        when {{ cleaned_country }} in ('MADAGASCAR', 'MG') then 'MG'
        when {{ cleaned_country }} in ('RWANDA', 'RW') then 'RW'
        when {{ cleaned_country }} in ('SOMALIA', 'SO') then 'SO'
        when {{ cleaned_country }} in ('SOUTHSUDAN', 'SS') then 'SS'
        when {{ cleaned_country }} in ('TANZANIA', 'TZ') then 'TZ'
        when {{ cleaned_country }} in ('UGANDA', 'UG') then 'UG'
        
        -- Africa - Southern
        when {{ cleaned_country }} in ('ANGOLA', 'AO') then 'AO'
        when {{ cleaned_country }} in ('BOTSWANA', 'BW') then 'BW'
        when {{ cleaned_country }} in ('LESOTHO', 'LS') then 'LS'
        when {{ cleaned_country }} in ('MALAWI', 'MW') then 'MW'
        when {{ cleaned_country }} in ('MOZAMBIQUE', 'MZ') then 'MZ'
        when {{ cleaned_country }} in ('NAMIBIA', 'NA') then 'NA'
        when {{ cleaned_country }} in ('SOUTHAFRICA', 'ZA') then 'ZA'
        when {{ cleaned_country }} in ('ZAMBIA', 'ZM') then 'ZM'
        when {{ cleaned_country }} in ('ZIMBABWE', 'ZW') then 'ZW'
        
        -- Oceania
        when {{ cleaned_country }} in ('AUSTRALIA', 'AU') then 'AU'
        when {{ cleaned_country }} in ('FIJI', 'FJ') then 'FJ'
        when {{ cleaned_country }} in ('NEWZEALAND', 'NZ') then 'NZ'
        when {{ cleaned_country }} in ('PAPUANEWGUINEA', 'PG') then 'PG'
        when {{ cleaned_country }} in ('SAMOA', 'WS') then 'WS'
        
        -- Return null if no match
        else null
    end
{% endmacro %}

