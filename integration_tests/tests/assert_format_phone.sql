-- Fails with one row per case where either mode disagrees with its expected value.
select *
from {{ ref('test_format_phone') }}
where actual_default is distinct from expected_default
    or actual_international is distinct from expected_international
