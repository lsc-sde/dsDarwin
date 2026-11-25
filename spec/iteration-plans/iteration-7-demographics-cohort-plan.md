# Iteration 7: `demographicsCohort` pair (HERON population)

Date: 2026-11-19. Builds on [iteration 6](iteration-6-cohort-constructor-plan.md).
ADR candidate (none written; for a human): the encoding of list and vector arguments through Opal. Here `ageRange` goes
as `list(c(<double>, <double>), ...)`, which Opal 6.1.3 with dsBase accepts. It changes what crosses the client/server
boundary.

## Why

HERON builds its study population with `CohortConstructor::demographicsCohort()`
([functions.R:181-198](https://github.com/heron-uk/HERON-UK-Characterisation)). The released run calls
`demographicsCohort(cdm, "population", sex = NULL)`; with age groups set it adds `ageRange = list(c(lo, hi), ...)`.
`docs/heron-analysis.md` marks fedn's `demographicsCohortDS` as **adapt**. fedn has two bugs:
- the client always sends `dsAssignSymbol`, which the server does not accept;
- the server treats the returned `cohort_table` as a cdm (`cdm <- do.call(...); cdm[[name]]`).

## Goals

- An analyst, through Opal, runs `ds.demographicsCohort(cdm, name, ageRange, sex, minPriorObservation)` and a cohort
  is built as `cdm$<name>`. The same flow is tested in DSLite on GiBleed, with counts equal to native.
- `ageRange` (a list of two-number vectors) goes through Opal (user, 2026-11-19).

## Non-goals

- `trimToDateRange`, HERON's `general_population` rename, aggregates (`cohortCountDS`), multi-concept `conceptSet`.
- Settling iteration 6's red tests (iteration 6 › Next 1).

## Approach

```
analyst:  ds.demographicsCohort("cdm", "population", ageRange = list(c(0, 17), c(18, 150)))
            -> buildDSCall(): NULL arguments dropped, ageRange as a list of doubles
            -> demographicsCohortDS(cdm = cdm, name = "population", ageRange = list(c(0, 17), c(18, 150)))
Rock:     demographicsCohortDS() -> checks -> CohortConstructor::demographicsCohort() -> cdm$population
```

- **NULL arguments are dropped by `buildDSCall`**, so server defaults apply and no `NULL` literal meets Opal's parser.
- **`ageRange` is sent as doubles**: integers deparse as ranges (`c(0L, 1L)` → `0:1`), and Opal refuses `:`.
- **Shared server guards** (`cdm` is a `cdm_reference`; `name` is not a CDM table other than a cohort) move into
  `dsDarwinHelpers::checkCohortTarget()`, used by both `*CohortDS` functions.
- **Server checks**: `sex` is `NULL` or one of `Both`/`Male`/`Female`; `minPriorObservation` is `NULL` or one
  non-negative whole number; `ageRange` is `NULL` or a list of numeric pairs, no `NA`, `>= 0`, lower `<=` upper.
  Messages name the argument, never data values.

## Files

- `helpers/dsDarwinHelpers/Client/R/helpers.R`: `buildDSCall` drops `NULL`s.
- `helpers/dsDarwinHelpers/Server/R/helpers.R`: `checkCohortTarget()`.
- `dsCohortConstructor/Server/R/demographicsCohortDS.R`; `conceptCohortDS.R` uses `checkCohortTarget()`;
  `inst/DATASHIELD` adds `demographicsCohortDS`.
- `dsCohortConstructor/Client/R/ds.demographicsCohort.R`.
- Tests in each package; `examples/concept-cohort.R` adds the population cohort and one `ageRange` call.

## Decisions

| Topic | Decision | Source |
|---|---|---|
| Arguments | `name`, `sex`, `minPriorObservation`, `ageRange` | user, 2026-11-19 |
| `ageRange` encoding | `list(c(double, double), ...)`; ADR candidate | user, 2026-11-19 |
| `NULL` arguments | dropped by the client | this plan |

## Done when

1. New tests pass in all four packages; no new failures beyond iteration 6's known red tests.
2. `Rscript examples/concept-cohort.R` on the local stack: `classDS("cdm$population")` → `"cohort_table"`, and the
   `ageRange` call is accepted by Opal.

## Server wrapper simplification

Flatten the optional argument guards and shorten the server documentation.
Keep validation before the upstream call, which creates the cohort table
before applying demographic filters. The existing server tests cover the
valid and invalid inputs. No additional ADR candidate.

## Client documentation

Use the concept cohort wrapper as the model for the demographics cohort help
page. Describe the server assignment and add a multi-study example. No ADR
candidate.
