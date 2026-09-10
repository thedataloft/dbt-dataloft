{#
    Timestamp normalisation.

    Ported from the originating client project's `handle_timestamps`. Public macro names are unchanged, because
    they are referenced by the dbt-timestamp-handling standard. All four now route
    through the dialect shims in `macros/dialect/timestamps.sql`; see that file for the
    Snowflake/DuckDB semantic difference around stored offsets.

    House convention, unchanged from the originating project: canonical timestamps are timezone-aware and
    UTC-aligned, and columns are named `<event>_at_utc`.
#}

{% macro to_utc_from_source_tz(source_timestamp) %}
    {#--
        Normalise a timestamp that already carries a source offset to UTC.
        Accepts TIMESTAMP_TZ / TIMESTAMPTZ or a string with an offset.

        Args:
            source_timestamp: e.g. '2025-01-01 12:00:00 -05:00'
        Returns:
            timezone-aware timestamp at the same instant, UTC-aligned
        Usage:
            select {{ to_utc_from_source_tz('event_ts') }} as event_at_utc from source
    #}
    {{ dbt_dataloft.to_utc_tz(source_timestamp) }}
{% endmacro %}


{% macro add_local_timezone(source_timestamp, local_timezone) %}
    {#--
        Attach a named timezone to a timestamp that has no offset.
        Accepts TIMESTAMP_NTZ / TIMESTAMP or a string.

        Args:
            source_timestamp: e.g. '2025-01-01 12:00:00'
            local_timezone:   quoted IANA name, e.g. "'America/Toronto'"
        Usage:
            select {{ add_local_timezone('event_ts', "'America/Toronto'") }} as event_at_local
    #}
    {%- set ts = "((" ~ source_timestamp ~ ") :: timestamp)" -%}
    {{ dbt_dataloft.make_timestamp_tz(
        "year(" ~ ts ~ ")", "month(" ~ ts ~ ")", "day(" ~ ts ~ ")",
        "hour(" ~ ts ~ ")", "minute(" ~ ts ~ ")", "second(" ~ ts ~ ")",
        local_timezone) }}
{% endmacro %}


{% macro now_utc() %}
    {#--
        The current instant, timezone-aware and UTC-aligned.

        Usage:
            select {{ now_utc() }} as loaded_at_utc
    #}
    {{ dbt_dataloft.current_timestamp_utc() }}
{% endmacro %}


{% macro date_to_local_timestamp(source_date, local_timezone) %}
    {#--
        Convert a date to the start of that day in a named timezone.
        Accepts DATE or a string.

        Args:
            source_date:    e.g. '2025-01-01'
            local_timezone: quoted IANA name, e.g. "'America/Toronto'"
        Usage:
            select {{ date_to_local_timestamp('event_date', "'America/Toronto'") }} as event_at_local
    #}
    {%- set d = "((" ~ source_date ~ ") :: date)" -%}
    {{ dbt_dataloft.make_timestamp_tz(
        "year(" ~ d ~ ")", "month(" ~ d ~ ")", "day(" ~ d ~ ")",
        0, 0, 0, local_timezone) }}
{% endmacro %}
