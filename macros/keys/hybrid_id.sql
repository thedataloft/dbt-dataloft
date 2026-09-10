{#
    Deterministic surrogate key: md5 of a namespaced source identifier.

    Ported unchanged from the originating client project's `generate_hybrid_id`. No dialect edits were needed --
    `md5(concat(...))` returns the same lowercase hex digest on both DuckDB and
    Snowflake (verified 2026-08-13).

    Note that `source_system` and `entity_type` are interpolated into a SQL string
    literal at compile time, so they must be Jinja literals, not column references.
    Only `original_id` is evaluated per row.

    Args:
        source_system: literal, e.g. 'sportsengine'
        entity_type:   literal, e.g. 'club'
        original_id:   column or expression

    Usage:
        {{ dbt_dataloft.hybrid_id('sportsengine', 'club', 'club_id') }}
#}
{% macro hybrid_id(source_system, entity_type, original_id) %}
    md5(concat('{{ source_system }}_{{ entity_type }}_', {{ original_id }}))
{% endmacro %}
