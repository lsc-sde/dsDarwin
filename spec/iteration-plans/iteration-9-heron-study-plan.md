# Iteration 9: HERON study code through DataSHIELD (`examples/Heron-study/`)

Date: 2026-11-23. Builds on [iteration 4](iteration-4-heron-analysis-design.md) (what HERON calls) and
[iteration 7](iteration-7-demographics-cohort-plan.md) (`ds.demographicsCohort`).
ADR candidates (none written; for a human): see the end.

## Why

HERON-UK Characterisation (`CharacterisationCode/`, commit `443059d`) runs natively as `CodeToRun.R` →
`RunCharacterisation.R` → `scripts/functions.R`. We need the same study as a DataSHIELD analyst script, so the
functions still to wrap are visible in the place they are called, in the order they have to be built.

## Goals

- `examples/Heron-study/` mirrors HERON's three files, so they diff against HERON line by line.
- Calls that exist today run: login, session `cdm` (`cdmFromConDS`), `ds.demographicsCohort`.
- Every call not developed yet is written as its intended `ds.*` call, commented out, with a
  `# NOT DEVELOPED [step N]` marker: client/server pair, assign or aggregate, what blocks it (user, 2026-11-23).
- Results only: the bound `summarised_result` exported as CSV, as HERON does.

## Non-goals

- Shiny app and `Report/`.
- Writing any of the backlog functions; Opal admin setup (stays in `examples/concept-cohort.R`).

## Backlog (the `[step N]` markers)

| Step | Client → server | Package (pair) | Type | Blocked on |
|---|---|---|---|---|
| 0 | `cdmFromConDS`, `ds.demographicsCohort` | dsCohortConstructor | assign | done |
| 1 | `ds.summariseOmopSnapshot` → `summariseOmopSnapshotDS` | dsOmopSketch (new) | aggregate | suppression rule (#16); first aggregate |
| 2 | `ds.summarisePerson` → `summarisePersonDS` | dsOmopSketch | aggregate | #16 |
| 3 | `ds.renameCohort` → `renameCohortDS` | dsCohortConstructor | assign | nothing: scalars only |
| – | **gate: argument encoding through Opal** (character vectors, nested lists, `Inf`; Date vectors go as ISO strings, iteration 11) | | | ADR candidate |
| 4 | `ds.trimToDateRange` → `trimToDateRangeDS` | dsCohortConstructor | assign | done ([iteration 11](iteration-11-trim-to-date-range-plan.md)) |
| 5 | `ds.summariseCharacteristics` → `summariseCharacteristicsDS` | dsCohortCharacteristics (new) | aggregate | `estimates` list; quantiles/density suppression |
| 6 | `ds.summariseObservationPeriod` → `summariseObservationPeriodDS` | dsOmopSketch | aggregate | #16 (dates as ISO strings) |
| 7 | `ds.summariseClinicalRecords` → `summariseClinicalRecordsDS` | dsOmopSketch | aggregate | character vectors; drops empty tables server-side; `conceptSummary` small cells |
| 8 | `ds.summariseTrend` → `summariseTrendDS` | dsOmopSketch | aggregate | character vectors; yearly small cells. **Tier 1 complete** |
| 9 | `ds.buildObservationPeriod` → `buildObservationPeriodDS` | dsOmopConstructor (new) | assign | `Inf`; result goes to `cdm_op`, not `cdm` |
| 10 | `ds.summariseImdRecords` → `summariseImdRecordsDS` | open | aggregate | package home; a CDM with IMD to test |

Not wrapped on purpose:
- `listSourceTables`, `dropSourceTable`: session tables vanish at logout.
- `isTableEmpty`: steps 7 and 8 drop empty tables on the server.
- `addSexQuery`: unreached with HERON's `sex = FALSE`.
- `createLogFile`, `logMessage`, `bind`, `settings`, `newSummarisedResult`, `exportSummarisedResult`: client-side
  omopgenerics on what the aggregates return.

## Approach

```
CodeToRun.R          settings, DSI login, cdm <- cdmFromConDS(), source(RunCharacterisation.R), logout
RunCharacterisation  log file, summariseImdRecords(), databaseCharacteristics(),
                     7 x summariseCustomObservationPeriod(), bind, exportSummarisedResult()
scripts/functions.R  the three HERON functions as client-side compositions of ds.* calls;
                     bindServers(): per-server list of summarised_result -> one summarised_result
```

- `dateRange = c(NA, NA)`: Delphi-100k has no data after 2011; HERON's released value is `2012-01-01 →`.
- `minCellCount = 5` stays for the client export; the servers suppress first with their own threshold (#16).
- `buildObservationPeriod` assigns into `cdm_op`, so `cdm` keeps the original `observation_period` for Tier 1. Each
  build rewrites `main.observation_period` in the session, so each build is summarised before the next one.

## Files

- `examples/Heron-study/CodeToRun.R`, `RunCharacterisation.R`, `scripts/functions.R`.
- `AGENTS.md`: repo layout, `examples/` line.

## Done when

1. All three files parse; markers for steps 1–10 are present.
2. On the local stack (`tilt up`, admin block of `examples/concept-cohort.R` run): `Rscript
   examples/Heron-study/CodeToRun.R` assigns `cdm`, builds `cdm$population`, logs "No results yet", logs out.

## ADR candidates

- Argument encoding through Opal for Date vectors, character vectors, nested lists and `Inf` (gates steps 4–9).
- Wrap granularity: one aggregate per DARWIN function makes HERON ~20 round trips per server.
- Home of study-specific server code (`summariseImdRecordsDS`): a DARWIN pair or a study package.
