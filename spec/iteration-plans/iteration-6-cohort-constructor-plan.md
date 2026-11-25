# Iteration 6: dsCohortConstructor, first pair (`conceptCohort`)

Date: 2026-11-17 to 2026-11-19. Builds on [iteration 3](iteration-3-cdm-session-plan.md).
ADR candidate (none written; for a human): the analyst-facing shape. CDM-changing assigns return the updated `cdm` to the
`cdm` symbol, and `conceptSet` holds one concept until an argument encoding is chosen.

## Why

Prove the whole path for one wrapped DARWIN function: package → Rock image → Opal publish → analyst call → cohort built
next to the data. The starting point is fedn-ds-sandbox's CohortConstructor code (ours, adapted freely).
Step by step (user, 2026-11-17): `conceptCohort` only. The first aggregate (`cohortCount`) comes later.

The CDM plugin (iteration 5, dsCDMConnector) is postponed. The `cdm` still comes from the iteration 3 script method
`cdmFromConDS()` + option `dsDarwin.cdm.path`. Package pins are #17; the suppression rule for good is #16.

## Goals

- An analyst, through Opal, runs `ds.conceptCohort(cdm, conceptSet = list(<name> = <concept id>), name)` and a cohort
  is built on Delphi-100k. The same flow is tested in DSLite on GiBleed.
- fedn's helpers (`R/helpers/wrapperHelpers.R`) are brought over and adapted, in packages the next pairs reuse.

## Non-goals

- Other fedn functions (`demographicsCohort`, `measurementCohort`, `requireDemographics`, `requireInDateRange`).
- Vectors and lists through Opal (multi-concept codelists, `ageRange`, `dateRange`).
- The CDM plugin (iteration 5), version pins (#17), the final suppression rule (#16).

## Anti-goals

fedn's "Avoid" list (`docs/heron-analysis.md` › Patterns from fedn): R code pasted as text, a client-set threshold,
writing into the CDM file, `sys.frame()` lookups, raw errors carrying data values.

## Approach

```
analyst (client):  ds.conceptCohort("cdm", list(gi_bleed = 192671), "gibleed")
                     -> makeAssignWrapper("conceptCohortDS") -> buildDSCall(): an R call object, not pasted text
                     -> DSI::datashield.assign.expr(conns, "cdm",
                          conceptCohortDS(cdm = cdm, conceptName = "gi_bleed", conceptId = 192671, name = "gibleed"))
Opal:              allows the call only if conceptCohortDS is published (inst/DATASHIELD, profile `default`)
Rock (server):     conceptCohortDS() -> CohortConstructor::conceptCohort() -> cdm$gibleed (cohort_table in in-memory `main`)
                     nothing comes back; dsBase classDS("cdm$gibleed") -> "cohort_table"
```

- **Four packages**, each a standalone R package: `dsCohortConstructor` (server) / `dsCohortConstructorClient` (client),
  plus the shared helpers `dsDarwinHelpers` (server) / `dsDarwinHelpersClient` (client). Install the helpers first.
- **Server packages in the Rock image**: the Dockerfile `R CMD INSTALL`s `dsDarwinHelpers` + `dsCohortConstructor`.
  Install happens on every image build (`tilt up`). Publish (`opalr::dsadmin.publish_package`) is a one-off admin call;
  redo it only when methods are added or renamed.
- **Injection safety comes from the call object.** A string like `"x'); ls(); ('"` stays one string value. The
  client helpers therefore check nothing: `AsSymbol()` marks a name and `buildDSCall()` passes everything else through.
  Opal's parser is the gate for symbols (`AsSymbol("ls()")` is refused by Opal: `ls` is not published).
- **Server checks**: `cdm` is a `cdm_reference`; `conceptId` is one positive whole number (cast with `as.integer`);
  `name` may replace an existing cohort but never another CDM table (e.g. `person`).

## Files

- `helpers/dsDarwinHelpers/Server/R/helpers.R`: `nfilterTab()` (`nfilter.tab` → `default.nfilter.tab` → stop),
  `applyDisclosureControl()` (counts in `(0, threshold)` → `NA` per cell, so one small cohort does not hide the
  others; pending #16). Unused until the first aggregate.
- `helpers/dsDarwinHelpers/Client/R/helpers.R`: `AsSymbol`, `buildDSCall`, `findConnections`,
  `makeAssignWrapper`, `makeAggregateWrapper`.
- `dsCohortConstructor/Server/R/conceptCohortDS.R`, `inst/DATASHIELD` (`AssignMethods: conceptCohortDS` only).
- `dsCohortConstructor/Client/R/ds.conceptCohort.R`.
- Tests: `tests/testthat/` in each package. Server tests call `conceptCohortDS` directly on omock GiBleed; client tests
  run through DSLite (`setup-dslite.R`: a `cdmFromConDS` assign method returning GiBleed; the cohort is checked with
  `dslite.server$getSessionData()`, a test-only look that Opal never allows).
- `deploy/Dockerfile`, `deploy/docker/docker-compose.yml` (build context = repo root), `.dockerignore` (whitelist:
  the Dockerfile and the two server packages, without their tests).
- `examples/concept-cohort.R`: admin publishes `cdmFromConDS`, the option and `dsCohortConstructor` (retries on 404);
  analyst builds `cdm$ckd` on Delphi, `classDS("cdm$ckd")` → `"cohort_table"`, `cdm$ckd` refused.
- `AGENTS.md`: repo layout and build commands for the four packages.
- `man/` is not tracked in git (`.gitignore`); `devtools::document()` makes it.

## Status (2026-11-19)

| Suite | Result |
|---|---|
| `helpers/dsDarwinHelpers/Server` | 4 pass, **2 fail**: "fails closed on a malformed threshold", "accepts a threshold set as a string" |
| `helpers/dsDarwinHelpers/Client` | 3 pass, **1 fails**: "findConnections refuses things that are not DSConnections" |
| `dsCohortConstructor/Server` | 7 pass |
| `dsCohortConstructor/Client` (DSLite) | 2 pass, **2 fail**: conceptSet shape check (client), snake_case `name` check (server) |
| `examples/concept-cohort.R` on Opal | not rerun; it now passes two codelists (`ckd`, `potassium`), which `ds.conceptCohort` cannot send yet |

The red tests are for checks that were removed from the code on 2026-11-19 (see Decisions). Either restore
the checks or delete the tests: user's call.
The string-threshold test matters for disclosure: if Opal hands options over as strings, `x < "5"` compares text.

## Found while building

- **DSLite runs the installed packages**, not the source folder. Reinstall the server package after every change.
  `devtools::load_all()` in the same R session before DSLite gives "configuration does not allow expression: conceptCohortDS".
- **Opal 6.1.3 with dsBase accepts lists and vectors in a call** (`classDS("list(a = c(1, 2))")` → `"list"`, checked
  live). A profile without dsBase must publish `c` and `list` itself.
- **R deparses consecutive integers as a range**: `c(192671L, 192672L)` → `192671:192672`. `:` is not published, so Opal
  refuses it, while DSLite accepts it. Any vector encoding must avoid this.
- CohortConstructor fixes a non-snake_case `name` with a warning (`Person -> person`); it does not error.
- A concept with no records gives an empty cohort (count 0) and a warning, not an error.
- `conceptId` arrives as a double; cast to integer before `omopgenerics::newCodelist()`.

## Alternatives looked at

- **Multi-concept `conceptSet`** (named list of vectors through Opal): built and working on 2026-11-18, reverted on
  2026-11-19 (user: to be rethought). Waits on the argument encoding (ADR candidate above).
- **Install from GitHub** (`dsadmin.install_github_package`): needs a push, lost when Rock is recreated, may 403.
- **Opal script methods per function** (`dsadmin.set_method`): no install needed, but the helpers would be copied into
  each method, and code that was never tested would run.
- **fedn's server helpers**: `getProjectCDM`/`registerProject` replaced by the session `cdm` (the registry comes back with
  the CDM plugin). `resolveServerObject`/`reconnectCohort`/`.dsEnvironment` dropped: Opal evaluates session symbols and
  the DuckDB connection lives for the session. `dsAssignSymbol` dropped (broke fedn's `demographicsCohortDS`).

## Decisions

| Topic | Decision | Source |
|---|---|---|
| Scope | `conceptCohort` only; `cohortCountDS`/`ds.cohortCount` removed | user, 2026-11-17 |
| Package names | `dsCohortConstructor` / `dsCohortConstructorClient`; folder `dsCohortConstructor/` | ADR-0002, user |
| Helpers | own packages `helpers/dsDarwinHelpers/{Server,Client}`, reused by later pairs | user |
| Server install | baked into the Rock image | user |
| Opal profile | `default`, next to dsBase; a dsBase-free `omop` profile is a later step | user |
| `conceptSet` | one codelist, one concept id per call | user, 2026-11-19 |
| Client checks | none: `buildDSCall` and `AsSymbol` only build the call | user, 2026-11-19 |
| `conceptName` / `name` checks | deferred (TODO in `conceptCohortDS`) | user, 2026-11-19 |
| Threshold | `nfilter.tab` → `default.nfilter.tab` → stop; never an argument or in `inst/DATASHIELD` | constraints |
| `man/` | not in git, generated | user |
| Commits | none by agents; the user reviews and commits | user |

## Next

1. Settle the red tests (Status): restore the checks or delete the tests. Decide on the string threshold first.
2. Fix `examples/concept-cohort.R` back to one codelist, or land the multi-concept encoding; rerun on Opal.
3. Multi-concept `conceptSet` and other vector arguments (`ageRange`, `dateRange`) once the encoding is chosen.
4. First aggregate (`cohortCountDS`) using `applyDisclosureControl`.
5. A dsBase-free `omop` profile (iteration 3 › Next 1); then pins (#17) and the CDM plugin (iteration 5).

## Done when

1. `devtools::test()` passes for all four packages (helpers installed first; server installed before the client run).
2. `devtools::check()`: 0 errors, 0 warnings for all four.
3. `cd deploy && tilt up` rebuilds the Rock image; `docker compose -p dsdarwin exec rock Rscript -e 'library(dsCohortConstructor)'` works.
4. `Rscript examples/concept-cohort.R` → `"cohort_table"`, `cdm$ckd` refused, exit 0 (twice: publishing is safe to rerun).
