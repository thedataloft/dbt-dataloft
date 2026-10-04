{#
    Render a list of test cases as a union-all of single-row selects -- portable where a
    `values` list is not (BigQuery has no VALUES in FROM). Seed CSVs are deliberately not
    used: they load '' as null and type '0044…' or '+1416…' as numbers, which would hide
    exactly the cases these models exist to test.

    Args:
        columns: list of column names
        rows:    list of tuples, one value per column. None becomes a typed null; a
                 string is quoted with the package's adapter-safe apostrophe escape.

    Adds `case_id`, the row's 1-based position, so a failing test names the case.
#}
{% macro case_rows(columns, rows) %}
    {%- for row in rows %}
    select
        {{ loop.index }} as case_id
        {%- for value in row %},
        {% if value is none -%}
        cast(null as {{ dbt.type_string() }})
        {%- else -%}
        '{{ value | replace("'", dbt_dataloft.escaped_quote()) }}'
        {%- endif %} as {{ columns[loop.index0] }}
        {%- endfor %}
    {% if not loop.last %}union all{% endif %}
    {%- endfor %}
{% endmacro %}
