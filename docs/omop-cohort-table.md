# OMOP cohort table

Most DARWIN EU tools produce or consume a cohort table. This note covers what one holds, which parts are row-level and must stay on the server, and which parts dsDarwin can return as summaries.
Full spec: the omopgenerics [cohorts article](https://darwin-eu.github.io/omopgenerics/articles/cohorts.html) and [`newCohortTable()`](https://darwin-eu.github.io/omopgenerics/reference/newCohortTable.html).

## The table

A cohort is a set of people, each with a time window. One row per person per cohort entry:

| Column | Meaning |
|---|---|
| `cohort_definition_id` | Which cohort (integer, a key into `settings()`) |
| `subject_id` | `person_id` from the CDM: links the entry to the person's rows in every OMOP table |
| `cohort_start_date` | Date of entry |
| `cohort_end_date` | Date of exit |

CohortConstructor reads the OMOP tables of a `cdm` and adds cohort tables to it; it never changes the OMOP tables.
The `cdm` comes from [omock](https://ohdsi.github.io/omock/) (synthetic, for tests) or [`CDMConnector::cdmFromCon()`](https://darwin-eu.github.io/CDMConnector/reference/cdmFromCon.html) (a database); both return the same `cdm_reference`.

## Attributes

A `cohort_table` carries these attributes, each read with an omopgenerics getter:

| Getter | Contents |
|---|---|
| [`settings()`](https://darwin-eu.github.io/omopgenerics/reference/settings.html) | One row per cohort: `cohort_definition_id`, `cohort_name`, plus the arguments that built it (`sex`, `age_range`, ...) |
| [`attrition()`](https://darwin-eu.github.io/omopgenerics/reference/attrition.html) | One row per cohort per step: `number_records`, `number_subjects`, `reason`, `excluded_records`, `excluded_subjects` |
| [`cohortCount()`](https://darwin-eu.github.io/omopgenerics/reference/cohortCount.html) | Final `number_records` and `number_subjects` per cohort (the last attrition row) |
| [`cohortCodelist()`](https://darwin-eu.github.io/omopgenerics/reference/cohortCodelist.html) | Concept IDs used to build each cohort (empty for demographic cohorts) |

## HERON's population cohort

HERON uses two CohortConstructor functions, both in `databaseCharacteristicsLocal()` ([`CharacterisationCode/scripts/functions.R`](https://github.com/heron-uk/HERON-UK-Characterisation/blob/main/CharacterisationCode/scripts/functions.R)):

```r
cdm$population <- CohortConstructor::demographicsCohort(cdm, "population", sex = sexCohort)
cdm$population <- cdm$population |>
  omopgenerics::newCohortTable(cohortSetRef = set, .softValidation = TRUE) |>  # renames cohort to "general_population"
  CohortConstructor::trimToDateRange(dateRange = as.Date(c("2012-01-01", NA)))
```

Its `omopgenerics::bind()` branch only runs when `ageGroup` is set; HERON leaves it `NULL`.

Working example: [`examples/cohort-walkthrough.R`](../examples/cohort-walkthrough.R) (`Rscript examples/cohort-walkthrough.R`) runs these steps on GiBleed and follows one person through them.
It shows where each function takes the entry's dates from ([`demographicsCohort()`](https://ohdsi.github.io/CohortConstructor/reference/demographicsCohort.html): `observation_period`; [`conceptCohort()`](https://ohdsi.github.io/CohortConstructor/reference/conceptCohort.html): the clinical record), how [`trimToDateRange()`](https://ohdsi.github.io/CohortConstructor/reference/trimToDateRange.html) cuts windows and drops people with no time left, and the summaries that can come back.

## What stays on the server, what can come back

Rule: anything with a `subject_id` or a person's own dates is row-level and stays on the server (**assign**).
Anything with one row per cohort or per step is a summary and can come back (**aggregate**), after suppressing small counts.
Pairs follow the [client-server-pair skill](../.agents/skills/client-server-pair/SKILL.md) and [ADR-0002](../spec/adr/0002-package-and-function-naming.md).

| Call | Row-level? | dsDarwin pair |
|---|---|---|
| Cohort table rows | Yes | Stay on the server and are never returned |
| `demographicsCohort()` | Creates rows | **assign**: `ds.demographicsCohort()` → `demographicsCohortDS()`. Required (HERON) |
| `trimToDateRange()` | Changes rows | **assign**: `ds.trimToDateRange()` → `trimToDateRangeDS()`. Required (HERON) |
| `renameCohort()` | Changes the cohort name | **assign**: `ds.renameCohort()` → `renameCohortDS()`. Optional: replaces HERON's `newCohortTable(cohortSetRef = )` rename with the same result |
| `attrition()` | Counts from the data | **aggregate**: `ds.attrition()` → `attritionDS()`. Recommended: HERON doesn't call it, but it is the analyst's only check on a cohort they can't see. Small counts suppressed in `excluded_records` and `excluded_subjects` too: a small difference between two steps singles out people |
| `cohortCount()` | Counts from the data | No pair: it is the last row of `attrition()` ([source](https://github.com/darwin-eu/omopgenerics/blob/main/R/cohortCount.R)), so the client takes it from `ds.attrition()` |
| `settings()`, `cohortCodelist()` | No, the analyst's own arguments and concept IDs | **aggregate** if needed, returned as is |
| `conceptCohort()` | Creates rows | **assign**: `ds.conceptCohort()` → `conceptCohortDS()`. Later, not used by HERON |
| [`measurementCohort()`](https://ohdsi.github.io/CohortConstructor/reference/measurementCohort.html) | Creates rows | Not wrapped yet: not used by HERON. Its `valueAsNumber` range lets the analyst probe one person's value by comparing counts across narrow ranges, so it needs its own plan. GiBleed measurements have no values, so tests need Delphi-100k or `omock::mockMeasurement()` |
| `bind()` | Changes rows | No pair: only HERON's `ageGroup` branch uses it |

Only functions the analyst calls get a pair; CohortConstructor's internals run unchanged inside the server function.
Other omopgenerics functions HERON calls either work on results already returned (`bind()` of results, `exportSummarisedResult()`: client side, no pair) or are server housekeeping (logging, `dropSourceTable()`: no pair).

Each server function must also guard what reaches the analyst outside its return value ([disclosure-control.md](../spec/constraints/disclosure-control.md)):

- **Errors.** omopgenerics validation errors list up to five `subject_id`s (`checkOverlap()` in [`classCohortTable.R`](https://github.com/darwin-eu/omopgenerics/blob/main/R/classCohortTable.R)), and DataSHIELD returns server errors to the client. Catch errors from wrapped packages and raise a generic message. 
  - In the `checkOverlap()` as the part of the `omopgenerics` package. It calls internally when we call the `newCohortTable()` when creating cohorts and changing rows. Need to create the output helper wrap so ds functions be handle output case
- **Small subsets.** An assign step that drops people (`trimToDateRange()`, later `require*()`) refuses results below `nfilter.subset`, as dsBase subset functions do.
- **Suppression in the server.** HERON suppresses only at export ([`exportSummarisedResult(minCellCount = )`](https://darwin-eu.github.io/omopgenerics/reference/exportSummarisedResult.html)); dsDarwin suppresses before returning.
