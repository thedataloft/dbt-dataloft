# dbt_dataloft

Cross-adapter dbt macros carried between Dataloft clients. Runs on **DuckDB** and
**Snowflake**.

```yaml
# packages.yml
packages:
  - git: "https://github.com/thedataloft/dbt-dataloft"
    revision: main
```

```sql
select
    {{ dbt_dataloft.format_phone('phone') }}                as phone_e164,
    {{ dbt_dataloft.format_state('state', 'postal_code') }} as state_code,
    {{ dbt_dataloft.validate_email('email') }}              as email,
    {{ dbt_dataloft.now_utc() }}                            as loaded_at_utc
from {{ source('crm', 'contacts') }}
```

| Macro | Returns |
|---|---|
| `format_phone(expr)` | E.164 `+1XXXXXXXXXX`, else null |
| `format_zip(expr)` | Five-digit US ZIP, else null |
| `format_state(expr[, zip_expr])` | Two-letter state code, with optional ZIP fallback |
| `format_country(expr)` | ISO 3166-1 alpha-2 code, else null |
| `standardize_gender(expr)` | `'Male'`, `'Female'`, `'Other'`, else null |
| `validate_email(expr)` | Lowercased, trimmed address if well-formed, else null |
| `hybrid_id(system, entity, id)` | Deterministic md5 surrogate key |
| `to_utc_from_source_tz(expr)` | UTC-aligned timestamp from one carrying an offset |
| `add_local_timezone(expr, tz)` | Attaches a named timezone to a naive timestamp |
| `date_to_local_timestamp(expr, tz)` | Start of that day in the named timezone |
| `now_utc()` | Current instant, UTC-aligned |

Generic tests: `composite_uniqueness` (multi-column uniqueness) and
`relationships_where` (referential integrity against a filtered target).

## Adding or changing a macro

Read [SKILL.md](./SKILL.md) first. It covers the `adapter.dispatch` pattern, the
specific Snowflake/DuckDB divergences these macros work around — including one that
fails **silently** rather than raising — and the regex escaping rule that follows from
it. Porting a macro without reading it is how the silent failure gets reintroduced.

## Status

Verified on **both adapters**, 2026-08-27.

| | |
|---|---|
| **DuckDB** 1.5.x (dbt-core 1.12.2 / dbt-duckdb 1.11.0) | 33 macro cases + both generic tests, green |
| **Snowflake** 10.30.101 (dbt-core 1.10.15 / dbt-snowflake 1.10.3) | 37 cases, green — run as a least-privilege dev role, materialising nothing |

Every case produced identical output on both, including the three deliberate dead
branches. `md5` agrees byte-for-byte across Snowflake, DuckDB and Python.

One difference is real and expected, not a defect: timezone-aware timestamps agree on
the **instant** on both adapters, but Snowflake retains the source offset in the rendered
text where DuckDB renders in the session zone. Store and compare these values; never
assert on their string form. See `macros/dialect/timestamps.sql`.

`format_state` carries three deliberate dead branches inherited from the original, so ZIPs in
American Samoa, the Northern Mariana Islands and the US Virgin Islands resolve to the
wrong code — identically on both adapters. Documented in the macro header and in SKILL.md.
