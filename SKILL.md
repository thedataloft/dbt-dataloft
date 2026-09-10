---
name: dbt-dataloft-macros
description: Use when writing dbt models that clean phone numbers, US states, ZIPs, countries or gender values, or when adding a macro to the dbt_dataloft package. Covers the adapter-dispatch pattern this package uses to run on both DuckDB and Snowflake.
---

# dbt_dataloft macros

Cross-adapter dbt macros carried between Dataloft clients. Runs on **DuckDB** and
**Snowflake**. There is no BigQuery implementation — see Adding an adapter.

## Available macros

Namespace every call: `{{ dbt_dataloft.<macro>(...) }}`.

| Macro | Returns |
|---|---|
| `format_phone(expr)` | E.164 `+1XXXXXXXXXX` for valid North American numbers, else null |
| `format_zip(expr)` | Five-digit US ZIP, else null. Handles ZIP+4 and restores lost leading zeros |
| `format_state(expr[, zip_expr])` | Two-letter state code. Falls back to ZIP ranges when `zip_expr` is given |
| `format_country(expr)` | ISO 3166-1 alpha-2 code, else null |
| `standardize_gender(expr)` | `'Male'`, `'Female'`, `'Other'`, else null |

## The dispatch pattern

Two functions diverge between DuckDB and Snowflake. Both are wrapped in
`macros/dialect/regex.sql` — **use the shims, never the raw functions**:

| Instead of | Use |
|---|---|
| `regexp_like(x, p)` / `regexp_matches(x, p)` | `{{ dbt_dataloft.regex_matches(x, 'p') }}` |
| `regexp_replace(...)` | `{{ dbt_dataloft.regex_replace_all(x, 'p', 'r') }}` |

Why each one matters, verified 2026-08-27 on DuckDB 1.5.x:

- `regexp_like` does not exist on DuckDB. Loud failure — a Catalog Error.
- Snowflake's 4-arg `regexp_replace(x, p, r, 1, 0)` does not bind on DuckDB. Also loud.
- **Silent** failure, the dangerous one: DuckDB's 3-arg `regexp_replace` replaces only
  the *first* match, while Snowflake's is already global. `regex_replace_all` adds
  DuckDB's `'g'` flag so both behave the same.

## Traps found by testing with bad data

Five, all verified on both adapters 2026-08-27. Three are fixed in the macros; two are
inherent and can only be avoided by not misusing the macro.

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

## Regex escaping

Write POSIX classes, not backslash escapes. `'[[:space:]]+'` works on both;
`'\\s+'` **silently matches nothing on DuckDB** — no error, the input passes through
unchanged. This is why `format_state` and `format_country` differ from their
originals, which render `'\\s+'`.

## Verified on both adapters

DuckDB 1.5.x and Snowflake 10.30.101, 2026-08-27 — 33 and 37 cases respectively, all
producing identical output. The Snowflake run used a least-privilege dev role and warehouse via
`dbt show --inline`, materialising nothing.

POSIX character classes (`[[:space:]]`, `[.]`) behave the same on both, which is what
makes the escaping rule above safe rather than merely convenient.

One observed difference, expected: timezone-aware timestamps agree on the instant, but
Snowflake keeps the source offset in the rendered text (`12:00 -05:00`) where DuckDB
renders in the session zone. Both compare and join correctly. A test that string-matches
an offset will pass on one and fail on the other while both are right.

## Adding an adapter

Add a `<adapter>__<name>` macro beside the existing `default__` and `snowflake__`
implementations in `macros/dialect/regex.sql`. `default__` currently targets DuckDB
and ANSI-ish SQL.

BigQuery is deliberately unimplemented: under ADR 0001 BigQuery is a landing and
serving layer with no dbt models. If a second, BigQuery-targeted project appears it
will need `bigquery__` variants (`REGEXP_CONTAINS`, `REGEXP_REPLACE`), plus
`cast(... as string)` in `standardize_gender` since BigQuery has no `::` operator, and
a replacement for `translate`, which BigQuery lacks entirely.

## Known carried-over defect

`format_state`'s ZIP fallback has three unreachable branches, preserved deliberately to
match the original rather than diverge silently: ZIPs `967xx` return `HI` not `AS`, `969xx`
return `GU` not `MP`, and `008xx` return `PR` not `VI`. American Samoa, the Northern
Mariana Islands and the US Virgin Islands cannot be produced from a ZIP. Details in the
macro's own header. Fixing means reordering the branches most-specific-first, and would
make this package disagree with the original.

## Before adding a macro

Ported macros must behave identically on both adapters. Prove it — build a model with
a `values` list of inputs and expected outputs and run it on DuckDB, rather than
reasoning about dialect support from documentation. Two of the four findings above
contradicted what a reasonable reading of the docs would suggest.
