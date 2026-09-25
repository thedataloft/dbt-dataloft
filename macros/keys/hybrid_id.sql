{#
    Deterministic surrogate key: md5 of a namespaced source identifier.

    Ported unchanged from the originating client project's `generate_hybrid_id` for DuckDB and Snowflake --
    `md5(concat(...))` returns the same lowercase hex digest on both (verified
    2026-08-13). BigQuery's `md5()` diverges: it returns BYTES, not a hex string, so an
    unmodified port would silently change this column's type and values with no error.
    Added 2026-09-21; `to_hex(md5(...))` restores the same lowercase hex digest.
    Verified 2026-09-25 against a live BigQuery instance: the same 20 keys came back
    byte-for-byte identical to DuckDB's.

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
  {{ return(adapter.dispatch('hybrid_id', 'dbt_dataloft')(source_system, entity_type, original_id)) }}
{% endmacro %}

{% macro default__hybrid_id(source_system, entity_type, original_id) %}
    md5(concat('{{ source_system }}_{{ entity_type }}_', {{ original_id }}))
{% endmacro %}

{% macro bigquery__hybrid_id(source_system, entity_type, original_id) %}
    to_hex(md5(concat('{{ source_system }}_{{ entity_type }}_', {{ original_id }})))
{% endmacro %}
