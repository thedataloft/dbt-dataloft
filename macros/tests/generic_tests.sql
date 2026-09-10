{#
    Generic tests carried between clients.

    Both ported unchanged from the originating client project (`test_composite_uniqueness`,
    `test_relationships_where`). Neither needed dialect edits -- they are plain ANSI
    SQL with no adapter-specific functions.
#}

{#
    Fail when the given combination of columns is not unique.

    dbt's built-in `unique` covers a single column; this covers a composite key without
    requiring a surrogate key column just to test it.

    Usage:
        tests:
          - dbt_dataloft.composite_uniqueness:
              column_names: ['club_id', 'season_id']
#}
{% test composite_uniqueness(model, column_names) %}

  with validation as (
      select
          {{ column_names | join(', ') }},
          count(*) as row_count
      from {{ model }}
      group by {{ column_names | join(', ') }}
      having count(*) > 1
  )

  select *
  from validation

{% endtest %}


{#
    Referential integrity against a filtered subset of the target.

    dbt's built-in `relationships` compares against the whole target table. This applies
    a WHERE clause first, for cases where only part of the target is a legitimate
    referent -- an active-records-only lookup, or a single season.

    `where_condition` is interpolated into the query unmodified, so it must come from
    project configuration, never from data.

    Usage:
        tests:
          - dbt_dataloft.relationships_where:
              to: ref('dim_club')
              field: club_id
              where_condition: "is_active"
#}
{% test relationships_where(model, column_name, to, field, where_condition) %}

  with source_data as (
      select distinct {{ column_name }} as source_value
      from {{ model }}
      where {{ column_name }} is not null
  ),

  target_data as (
      select {{ field }} as target_value
      from {{ to }}
      where {{ where_condition }}
  ),

  validation as (
      select
          s.source_value
      from source_data s
      left join target_data t
          on s.source_value = t.target_value
      where t.target_value is null
  )

  select *
  from validation

{% endtest %}
