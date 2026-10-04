---
name: dbt-dataloft-macros
description: Use when writing dbt models that clean phone numbers, US states, Canadian provinces, ZIPs and postal codes, countries or gender values, or when adding a macro to the dbt_dataloft package. Covers the adapter-dispatch pattern this package uses to run on DuckDB, Snowflake and BigQuery.
---

# dbt_dataloft macros

Cross-adapter dbt macros carried between Dataloft clients. Runs on **DuckDB**,
**Snowflake** and **BigQuery**, verified on all three.

## Available macros

Namespace every call: `{{ dbt_dataloft.<macro>(...) }}`.

| Macro | Returns |
|---|---|
| `format_phone(expr)` | E.164 `+1XXXXXXXXXX` for valid North American numbers, else null |
| `format_zip(expr)` | Five-digit US ZIP, else null. Handles ZIP+4 and restores lost leading zeros |
| `format_state(expr[, zip_expr])` | Two-letter state code. Falls back to ZIP ranges when `zip_expr` is given |
| `format_postal(expr[, country_expr])` | US five-digit ZIP (as `format_zip`) or Canadian `A1A 1A1`, else null. Without `country_expr` the country is read from the value's shape |
| `format_state_province(expr[, postal_expr[, country_expr]])` | Two-letter US state or Canadian province/territory code. Postal fallback uses ZIP prefixes or the postal code's first letter. Its ZIP ranges are corrected — see below |
| `format_country(expr)` | ISO 3166-1 alpha-2 code, else null |
| `standardize_gender(expr)` | `'Male'`, `'Female'`, `'Other'`, else null |
| `format_name(expr)` | Proper-cased name, trimmed — Snowflake `initcap` default semantics on every adapter (`o'brien` → `O'brien`, `mary-jane` → `Mary-Jane`) |

## The dispatch pattern

Several functions diverge across DuckDB, Snowflake and BigQuery. All are wrapped in
`macros/dialect/` — **use the shims, never the raw functions**:

| Instead of | Use |
|---|---|
| `regexp_like(x, p)` / `regexp_matches(x, p)` / `regexp_contains(x, p)` | `{{ dbt_dataloft.regex_matches(x, 'p') }}` |
| `regexp_instr(...) > 0` / `regexp_contains(...)` (substring) | `{{ dbt_dataloft.regex_contains(x, 'p') }}` |
| `regexp_replace(...)` | `{{ dbt_dataloft.regex_replace_all(x, 'p', 'r') }}` |
| `cast(x as varchar)` / `x::varchar` | `{{ dbt_dataloft.as_string(x) }}` (BigQuery has no VARCHAR or `::`) |

Why each one matters, verified 2026-08-27 on DuckDB 1.5.x:

- `regexp_like` does not exist on DuckDB. Loud failure — a Catalog Error.
- Snowflake's 4-arg `regexp_replace(x, p, r, 1, 0)` does not bind on DuckDB. Also loud.
- **Silent** failure, the dangerous one: DuckDB's 3-arg `regexp_replace` replaces only
  the *first* match, while Snowflake's is already global. `regex_replace_all` adds
  DuckDB's `'g'` flag so both behave the same. BigQuery's `regexp_replace` is global by
  default like Snowflake's, so the shim adds no flag there.
- BigQuery has no VARCHAR type and no `::` cast operator — `cast(x as varchar)` is a
  parse error there, not a silent divergence, but it's still routed through
  `as_string` so callers don't hardcode a type name that doesn't exist on all three.

Two macros that used to be adapter-agnostic plain SQL are now dispatched too, because
the BigQuery equivalent genuinely differs in output, not just syntax:

- `hybrid_id` — BigQuery's `md5()` returns `BYTES`, not a hex string like DuckDB and
  Snowflake's. `bigquery__hybrid_id` wraps it in `to_hex(...)` to match.
- `standardize_gender` — routes its cast through `as_string` instead of a hardcoded
  `::varchar`.

## Traps found by testing with bad data

Six. The first five were verified on DuckDB and Snowflake 2026-08-27; the sixth on
DuckDB and BigQuery 2026-09-25. Three are fixed in the macros; three are inherent and can
only be avoided by not misusing the macro.

**Fixed — `regex_matches` is full-match only.** Snowflake's `regexp_like` is implicitly
anchored to the whole string; DuckDB's `regexp_matches` is a substring search. So
`'[A-Za-z]'` matches `'M5V 3A8'` on DuckDB and **fails on Snowflake**. Anchor every
pattern, or use `regex_contains` for substring semantics. The existing macros all passed
their tests only because every pattern already used `^…$`.

**Fixed — a non-US postcode used to become a plausible US ZIP.** `'M5V 3A8'` stripped to
`538`, padded to `00538`, and passed the range check. `format_zip` now rejects anything
containing a letter first.

**Fixed — an empty-string timestamp used to fail the whole build.** The timestamp macros
now use `try_cast`, so unparseable input yields null like every other macro here. Empty
strings are common in real extracts; CSV-to-parquet produces `''` far more often than NULL.

**Inherent — `format_phone` cannot detect non-North-American numbers.** A London
`2071234567` becomes `+12071234567`, a valid-looking Maine number. The information is not
in the digits. Only apply it to a column you know is NANP.

**Inherent — an all-digit string is a valid timestamp to Snowflake, not to DuckDB.**
`'90210'` casts to 1970-01-02 on Snowflake (epoch seconds) and null on DuckDB. Both are
defensible, so it is not normalised. Guard the input, or convert epochs explicitly.

**Inherent — `make_timestamp_tz` rounds a fractional second on BigQuery and keeps it on
DuckDB.** BigQuery's `DATETIME()` takes an INT64 seconds argument, and its `CAST` to
INT64 rounds half away from zero rather than truncating — measured 2026-09-25: `30.5`→`31`,
`30.4`→`30`, `31.5`→`32`. So `second = 30.5` yields `:30.5` on DuckDB and `:31` on
BigQuery. Not normalised, because it is unreachable through the two wrappers —
`add_local_timezone` gets whole seconds from DuckDB's `second()`, which returns BIGINT,
and `date_to_local_timestamp` passes a literal `0`. **Pass whole seconds if you call
`make_timestamp_tz` directly.**

## Why `format_name` exists

`dbt-coding-standards` mandates proper-cased names, and the obvious `initcap(trim(x))` does not
exist on DuckDB — Catalog Error, found 2026-09-10 by the first DuckDB client's first staging
model. `format_name` dispatches: `initcap(trim(x))` on Snowflake, a regex split-and-capitalise on
DuckDB. The DuckDB side deliberately copies Snowflake's *default* word semantics — apostrophes are
word characters, so `o'brien` → `O'brien` on both — because identical output is the contract; a
prettier `O'Brien` on one adapter would be exactly the silent divergence this package exists to
remove. Verified side by side on both adapters, 10 cases including empty, whitespace-only and null.

## Regex escaping

Write POSIX classes, not backslash escapes. `'[[:space:]]+'` works on both;
`'\\s+'` **silently matches nothing on DuckDB** — no error, the input passes through
unchanged. This is why `format_state` and `format_country` differ from their
originals, which render `'\\s+'`.

## Verified on all three adapters

DuckDB 1.5.x and Snowflake 10.30.101, 2026-08-27 — 33 and 37 cases respectively, all
producing identical output. The Snowflake run used a least-privilege dev role and warehouse via
`dbt show --inline`, materialising nothing.

POSIX character classes (`[[:space:]]`, `[.]`) behave the same on all three, which is
what makes the escaping rule above safe rather than merely convenient. RE2 is BigQuery's
regex engine and supports them; confirmed by running them, 2026-09-25.

One observed difference, expected: timezone-aware timestamps agree on the instant, but
Snowflake keeps the source offset in the rendered text (`12:00 -05:00`) where DuckDB
renders in the session zone. Both compare and join correctly. A test that string-matches
an offset will pass on one and fail on the other while both are right. BigQuery's
TIMESTAMP behaves like DuckDB's here (no retained offset), confirmed 2026-09-25.

## Adding an adapter

Add a `<adapter>__<name>` macro beside the existing `default__`, `snowflake__` and
`bigquery__` implementations in `macros/dialect/`. `default__` currently targets DuckDB
and ANSI-ish SQL.

### BigQuery: verified 2026-09-25, and what the run caught

BigQuery variants exist for every dispatched macro (`macros/dialect/regex.sql`,
`macros/dialect/timestamps.sql`, `macros/dialect/casts.sql`, `hybrid_id`, `format_name`,
`add_local_timezone`, `date_to_local_timestamp`). Verified by a differential run against
a live project: the same sample rows through the same models on DuckDB and BigQuery, 65
rows across 4 models, byte-identical. `translate` was not changed and needed no change.

**Two defects that reading Google's documentation did not catch.** Both are worth
knowing because both would recur in any macro written the same way:

1. **BigQuery rejects the doubled-quote escape.** `'it''s'` is the SQL standard and works
   on DuckDB and Snowflake; BigQuery ends the string at the first quote and reports
   *"concatenated string literals must be separated by whitespace"*. `validate_email`'s
   pattern contained one. Fixed with `escaped_quote()` in `macros/dialect/regex.sql`
   rather than by rewriting the pattern, so DuckDB and Snowflake output stays identical.
2. **A dispatched macro is no use if its caller is not dispatched.** `make_timestamp_tz`
   had a working `bigquery__` variant, but `add_local_timezone` and
   `date_to_local_timestamp` built its arguments with `year(...)`, `month(...)` and a
   `::` cast — none of which exist on BigQuery. Both wrappers are now dispatched, and the
   BigQuery branches skip part-decomposition entirely (`timestamp(datetime_expr, tz)`
   takes a naive DATETIME directly). **When adding an adapter, check the callers, not
   just the dispatched macro.**

**`bigquery__make_timestamp_tz` needed covering separately.** Both its callers bypass it
on BigQuery, so no model reaches it; calling it directly with literal parts does. Whole
seconds agree with DuckDB including DST both ways. A fractional second does not — see the
sixth trap below.

**How the comparison was done**, if it needs repeating for another adapter: build the
same models on both engines, changing only the `FROM` clause, and diff normalised
exports. Normalise in the *client*, not in SQL — timestamps to epoch microseconds
(compare instants, never rendered text, per the divergence documented above), decimals to
a fixed scale, NULL to a visible sentinel, and replace `now_utc()` with a bounded
freshness assertion rather than dropping it, so a UTC-vs-local bug still surfaces.

## Known carried-over defect

`format_state`'s ZIP fallback has three unreachable branches, preserved deliberately to
match the original rather than diverge silently: ZIPs `967xx` return `HI` not `AS`, `969xx`
return `GU` not `MP`, and `008xx` return `PR` not `VI`. American Samoa, the Northern
Mariana Islands and the US Virgin Islands cannot be produced from a ZIP. Details in the
macro's own header. Fixing means reordering the branches most-specific-first, and would
make this package disagree with the original.

**`format_state_province` does not carry it.** Its ZIP fallback is checked
most-specific-first and returns the correct code for the three cases above — plus five more
prefixes `format_state` also gets wrong: `202`–`205` (DC, not VA), `755`–`759` (TX, not AR),
`005` (NY, not null), `055` (MA, not VT) and `340` (Armed Forces Americas: null, not FL).
Note that a naive reorder is *not* enough: `967` is mostly Hawaii, and only `96799` is
American Samoa; only `96950`–`96952` are the Northern Mariana Islands. The full list is in the
macro header. Use `format_state_province` when correctness matters more than matching the
original.

## Before adding a macro

Ported macros must behave identically on every adapter. Prove it — build a model with
a `values` list of inputs and expected outputs and run it, rather than reasoning about
dialect support from documentation. Two of the four DuckDB/Snowflake findings above
contradicted what a reasonable reading of the docs would suggest, and so did both of the
BigQuery ones.