{#
    Fails with one row per case where `column_name` differs from the `expected` column.
    Null-safe: null expected and null actual is a pass.
#}
{% test matches_expected(model, column_name, expected) %}
select *
from {{ model }}
where {{ column_name }} is distinct from {{ expected }}
{% endtest %}
