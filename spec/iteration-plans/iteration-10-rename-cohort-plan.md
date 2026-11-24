# Iteration 10: `renameCohort` pair (HERON step 3)

Date: 2026-11-24. Builds on [iteration 9](iteration-9-heron-study-plan.md) (backlog step 3).
ADR candidates: none. Uses the helpers only (ADR-0004, Proposed); file names follow the existing pairs, no `assign-` prefix (user, 2026-11-24).

## Why

HERON names the population cohort `general_population` with `settings()` + `newCohortTable(cohortSetRef = set)`.
Through DataSHIELD that would ship a data frame to the server; `CohortConstructor::renameCohort()` does the same
with scalars. HERON runs with `ageGroup <- NULL` (`RunCharacterisation.R:43`), so one cohort gets one new name.

## Goals

- `ds.renameCohort(cdm, cohort, newCohortName, cohortId = NULL)` renames a cohort in `cdm$<cohort>` on every server.
- `examples/Heron-study/scripts/functions.R` step 3 runs instead of being commented out.

## Non-goals

- Several new names in one call (character vector through Opal): waits on the argument-encoding ADR candidate
  (iteration 9). One `cohortId` is a scalar and goes through.
- The `assign-*` file prefix from ADR-0004: applied to every pair at once in that PR, if accepted.

## Approach

```
ds.renameCohort("cdm", "population", "general_population")
  -> makeAssignWrapper("renameCohortDS") -> assign to `cdm`:
     renameCohortDS(cdm = cdm, cohort = "population", newCohortName = "general_population")
Rock: checkCohortTarget(cdm, cohort) -> cdm[[cohort]] <- CohortConstructor::renameCohort(cdm[[cohort]], ...)
```

Server checks: `checkCohortTarget()` (a `cdm_reference`; never a CDM table such as `person`). CohortConstructor
validates the rest: a missing cohort, empty or duplicate names, an unknown `cohortId`. Its messages carry only what
the analyst sent. A non-snake_case name is fixed with a warning (`General Pop -> general_pop`), as upstream.

## Files

- `dsCohortConstructor/Server/R/renameCohortDS.R`, `inst/DATASHIELD` (`AssignMethods: renameCohortDS`).
- `dsCohortConstructor/Server/tests/testthat/test-renameCohortDS.R` (GiBleed).
- `dsCohortConstructor/Client/R/ds.renameCohort.R`, `tests/testthat/test-ds.renameCohort.R` (DSLite).
- `examples/Heron-study/scripts/functions.R`: step 3 uncommented.

## Done when

1. New server and client tests pass; no new failures beyond the known red ones (iteration 6, 7).
2. Rock image rebuilt, `renameCohortDS` published in Opal, and on Delphi-100k the renamed cohort is a
   `cohort_table` checked through the DataSHIELD MCP.
