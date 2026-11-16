# Iteration 3: the CDM in a DataSHIELD session

Date: 2026-11-09 to 2026-11-10. Builds on [iteration 2](iteration-2-delphi-data-plan.md).
ADR candidate: an Opal option replaces the resource route of [ADR-0003](../adr/0003-cdm-through-opal-resource.md) (Proposed).
A human decides whether ADR-0003 is rejected, superseded or rewritten.

## Why

Iteration 2 builds a `cdm` only in an admin session (`opalr::opal.execute`). Analysts need it in a DataSHIELD session.
The client cannot open the file itself: Opal only runs published methods
(`quote(DBI::dbConnect(...))` → 400 parse error at `::`). A server function published in Opal must open it.

## Approach

```
admin   (opalr): publish cdmFromConDS as an assign method; set option dsDarwin.cdm.path = /data/delphi-100k.duckdb;
                 create user analyst with DataSHIELD "use"; enable the profile
analyst (DSI):   datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))   -> `cdm` stays in Rock
                 datashield.aggregate(conns, quote(classDS("cdm")))           -> "cdm_reference"
Rock:            cdmFromConDS(): in-memory DuckDB + ATTACH <path> AS cdm (READ_ONLY) -> CDMConnector::cdmFromCon()
```

- **No package yet.** `opalr::dsadmin.set_method(o, "cdmFromConDS", func = cdmFromConDS, type = "assign")` stores the
  function's code in the Opal profile as an "R script" method. It survives restarts (on `opal-home`).
- **The analyst passes nothing**: no path, no schema. The path is a DataSHIELD option set by the admin; Opal runs
  `options(...)` with every profile option at the start of each session, and `cdmFromConDS()` reads it with `getOption()`.
- **Read-only attach**: the `omop-data` volume is mounted `:ro`; many sessions read the file at once; each session's
  cohort tables go into its own in-memory `main` and vanish at logout. Opening the file read-write (fedn, dsOMOP)
  locks out other sessions; opening it `read_only = TRUE` leaves nowhere to write cohorts.

## Files

- `deploy/scripts/cdm-test.R`: the whole flow, admin then analyst, against the local stack.
  `Rscript deploy/scripts/cdm-test.R` → `"cdm_reference"`, then `cdm$person` refused ("must invoke a function"), exit 0.
- `deploy/scripts/smoke-test.R`: unchanged from iteration 2 (dsBase methods listed).

## What an analyst cannot do (checked as `analyst`, 2026-11-10)

| Attempt | Result |
|---|---|
| `cdm$person` | refused by Opal: "must invoke a function" |
| `ls()`, `head(cdm$person)`, `as.data.frame(cdm$person)` | refused by Opal: no such published method |
| `cdmFromConDS()` as an aggregate | refused by Opal: published as assign only |
| `opalr::dsadmin.set_option(...)` | 403: admin only |
| dsBase with the table as argument (`classDS(cdm$person)`, `meanDS(cdm$person$year_of_birth)`, `table1DDS(...)`) | **passes Opal**, fails in Rock only because dsBase does not understand a lazy `cdm` table |

The last row is protection by accident. Next step 1 makes it by design.

## Found while building (verified on the local stack)

- **Option names must be valid R names.** An option `delphi-100k` made Opal's session start run
  `options(..., delphi-100k='...')` → R syntax error → every DataSHIELD session failed, for every user. Use dots: `dsDarwin.cdm.path`.
- **An Opal restart disables the `default` profile** (a Rock restart does not). Listing methods still works; sessions fail
  with "DataSHIELD profile is not enabled". Fix: `opalr::dsadmin.profile_enable(o, "default")`.
- **Rock's `/var/lib/rock/R/library` is not on a volume** (only `rock-home → /srv`, `omop-data → /data`): packages installed
  into a running Rock are lost when the container is recreated. Server packages belong in the Rock image.
- Opal 6.1.3 refuses `opalr::dsadmin.install_local_package()` with 403.
- `opalr::dsadmin.installed_package()` answers TRUE before Rock serves packages; a publish right after gets 404. Retry the publish.
- A refused DataSHIELD call is an R error in DSI: wrap expected refusals in `try()`, or the script stops before `datashield.logout()`.

## Alternatives looked at

- **Opal resource + resourcer connector** (`datashield.assign.resource`): proven (project `omop` without a database,
  resource `omop.delphi` = `duckdb:///data/delphi-100k.duckdb`, a 19-line `resourcer::DBIResourceConnector`; two concurrent
  sessions, 99,523 persons). Dropped for now: more moving parts than one local DuckDB file needs. Revisit for real sites
  (Postgres: resourcer's built-in connector, passwords as resource secrets, per-project permissions, several CDMs by name).
  Leftover in local Opal: project `omop` / resource `delphi`, now unusable (its resolver package is gone).
- **dsOMOP** ([lsc-sde/datashield_omop_example](https://github.com/lsc-sde/datashield_omop_example)): works, but gives its own
  handle, cohort language and data frames, never a `cdm_reference`, so DARWIN packages cannot use it; opens DuckDB read-write.
  Worth reading for disclosure control (#16).
- **fedn-ds-sandbox**: same core (`dbConnect` + `cdmFromCon`), but the path comes from the analyst's script, which only works on DSLite.

## Decisions

| Topic | Decision | Source |
|---|---|---|
| Where the path comes from | DataSHIELD option `dsDarwin.cdm.path`, set by the Opal admin | user |
| Where the server code lives | Opal script method, defined in `cdm-test.R`; a server package later | user |
| Schemas | Fixed in `cdmFromConDS` (CDM as catalog `cdm`, cohorts in in-memory `main`), never analyst arguments | |
| Unset option | No check: an unset option fails inside DBI | user |

## Next

1. A separate DataSHIELD profile (e.g. `omop`) with only the CDM methods and no dsBase, restricted to analysts; remove the
   analyst's server-wide "use" on `default`. Then dsBase cannot be pointed at `cdm`.
2. First CohortConstructor pair on the `cdm`: an assign (`conceptCohortDS`) and an aggregate with `nfilter.tab` suppression.
3. Later: `cdmFromConDS` and the wrappers in a server package with tests, baked into the Rock image; Opal setup on `tilt up`.

## Done when

1. `Rscript deploy/scripts/cdm-test.R` exits 0 as `analyst`: `"cdm_reference"` returned, `cdm$person` refused.
