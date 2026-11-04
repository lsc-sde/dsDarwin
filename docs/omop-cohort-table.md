# OMOP cohort table

Most DARWIN EU tools produce or consume a cohort table. This note covers what one holds, which parts are row-level and must stay on the server, and which parts dsDarwin can return as summaries.
Full spec: the omopgenerics [cohorts article](https://darwin-eu.github.io/omopgenerics/articles/cohorts.html) and [`newCohortTable()`](https://darwin-eu.github.io/omopgenerics/reference/newCohortTable.html).

## The table

One row per person per cohort entry:

| Column | Meaning |
|---|---|
| `cohort_definition_id` | Which cohort (integer, a key into `settings()`) |
| `subject_id` | `person_id` from the CDM |
| `cohort_start_date` | Date of entry |
| `cohort_end_date` | Date of exit |

With `.softValidation = FALSE` (the default), omopgenerics checks for: no missing values, `start <= end`, no overlapping entries for the same subject in the same cohort, and entries that fall inside an observation period. HERON skips these checks with `.softValidation = TRUE` when it renames the cohort.

## Attributes

A `cohort_table` carries these attributes, each read with an omopgenerics getter:

| Getter | Contents |
|---|---|
| [`settings()`](https://darwin-eu.github.io/omopgenerics/reference/settings.html) | One row per cohort: `cohort_definition_id`, `cohort_name`, plus the arguments that built it (`sex`, `age_range`, ...) |
| [`attrition()`](https://darwin-eu.github.io/omopgenerics/reference/attrition.html) | One row per cohort per step: `number_records`, `number_subjects`, `reason`, `excluded_records`, `excluded_subjects` |
| [`cohortCount()`](https://darwin-eu.github.io/omopgenerics/reference/cohortCount.html) | Final `number_records` and `number_subjects` per cohort (the last attrition row) |
| [`cohortCodelist()`](https://darwin-eu.github.io/omopgenerics/reference/cohortCodelist.html) | Concept IDs used to build each cohort (empty for demographic cohorts) |

## Worked example: HERON's population cohort

HERON builds its general population cohort in `databaseCharacteristicsLocal()` ([`CharacterisationCode/scripts/functions.R`](https://github.com/heron-uk/HERON-UK-Characterisation/blob/main/CharacterisationCode/scripts/functions.R)):

```r
cdm$population <- CohortConstructor::demographicsCohort(cdm, "population", sex = sexCohort)
cdm$population <- cdm$population |>
  omopgenerics::newCohortTable(cohortSetRef = set, .softValidation = TRUE) |>  # renames cohort to "general_population"
  CohortConstructor::trimToDateRange(dateRange = as.Date(c("2012-01-01", NA)))
result$populationCharacteristics <- CohortCharacteristics::summariseCharacteristics(cdm$population, ...)
```

The `omopgenerics::bind()` branch above it only runs when `ageGroup` is set, which HERON leaves as `NULL`.

The same steps on GiBleed (CohortConstructor 0.6.3, omopgenerics 1.4.0):

```r
cdm <- omock::mockCdmFromDataset("GiBleed", source = "duckdb")
cdm$population <- CohortConstructor::demographicsCohort(cdm, "population", sex = "Both")
cdm$population <- CohortConstructor::trimToDateRange(cdm$population, dateRange = as.Date(c("2012-01-01", NA)))
```

```
> head(cdm$population, 3)                      # row-level: never leaves the server
  cohort_definition_id subject_id cohort_start_date cohort_end_date
1                    1        123 2012-01-01        2013-07-17
2                    1        129 2012-01-01        2018-07-02
3                    1         16 2012-01-01        2017-11-02

> settings(cdm$population)
  cohort_definition_id cohort_name  sex
1                    1 demographics Both

> cohortCount(cdm$population)
  cohort_definition_id number_records number_subjects
1                    1           2540            2540

> attrition(cdm$population)
  number_records number_subjects reason_id reason                                  excluded_records excluded_subjects
1           2694            2694         1 Initial qualifying events                              0                 0
2           2694            2694         2 Non-missing sex                                        0                 0
3           2694            2694         3 Sex requirement: Both                                  0                 0
4           2540            2540         4 cohort_start_date trimmed >= 2012-01-01              154               154
```

- [`demographicsCohort(cdm, name, ageRange, sex, minPriorObservation)`](https://ohdsi.github.io/CohortConstructor/reference/demographicsCohort.html): one entry per person per observation period that meets the criteria. The default `cohort_name` is `demographics`; HERON renames it with `newCohortTable(cohortSetRef = )`.
- [`trimToDateRange(cohort, dateRange, ...)`](https://ohdsi.github.io/CohortConstructor/reference/trimToDateRange.html): moves start and end dates into the range, drops entries left outside it, and adds an attrition row.

## What stays on the server, what can come back

| Object or call | Row-level? | dsDarwin |
|---|---|---|
| Cohort table rows | Yes | Stays on the server and is never returned |
| `demographicsCohort()` | Creates rows | **assign**: `ds.demographicsCohort()` → `demographicsCohortDS()` |
| `trimToDateRange()` | Changes rows | **assign**: `ds.trimToDateRange()` → `trimToDateRangeDS()` |
| `newCohortTable(cohortSetRef = )`, `bind()` | Changes rows | assign if needed; HERON uses it only to rename the cohort (open question below) |
| `settings()` | No, it's metadata | **aggregate**, safe to return as is |
| `cohortCodelist()` | No, it's concept IDs | **aggregate**, safe to return as is |
| `cohortCount()` | Counts | **aggregate**, suppress small counts |
| `attrition()` | Counts | **aggregate**, suppress small counts, `excluded_*` too: a small difference between two steps singles out people |
| `CohortCharacteristics::summariseCharacteristics()` | Summary | **aggregate** in a later package; `min`/`max` of dates and ages are one person's values, so they are disclosive |

Names follow [ADR-0002](../spec/adr/0002-package-and-function-naming.md); output rules follow [disclosure-control.md](../spec/constraints/disclosure-control.md).

HERON suppresses only at export ([`exportSummarisedResult(minCellCount = )`](https://darwin-eu.github.io/omopgenerics/reference/exportSummarisedResult.html)).
In dsDarwin, suppression must happen in the server function, before anything is returned.
Which threshold to use (`nfilter.tab` or `minCellCount`) is still open: #16.

## Open questions

- Should `ds.demographicsCohort()` take the cohort name directly, so no rename wrapper (`newCohortTable(cohortSetRef = )`) is needed?
- Suppression threshold: #16.
