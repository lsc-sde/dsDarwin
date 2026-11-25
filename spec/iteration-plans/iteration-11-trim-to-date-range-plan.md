# Iteration 11: `trimToDateRange` pair (HERON step 4)

Date: 2026-11-25. Builds on [iteration 9](iteration-9-heron-study-plan.md) (backlog step 4) and
[iteration 10](iteration-10-rename-cohort-plan.md) (pair shape).
ADR candidates: none new. The iteration-9 candidate (argument encoding through Opal) stays open; this pair sends dates as
ISO strings (user, 2026-11-25).

## Why

HERON trims the population cohort to the study window with
`trimToDateRange(dateRange = as.Date(c("2012-01-01", NA)))`. A `Date` deparses to
`structure(c(15340, NA), class = "Date")`, and Opal only runs nested calls that are registered DataSHIELD methods
(`c` and `list` come from dsBase; `structure` does not), so a `Date` cannot cross as is.

## Goals

- `ds.trimToDateRange(cdm, cohort, dateRange, cohortId = NULL)` trims `cdm$<cohort>` on every server.
  `dateRange` is a `Date` or `"YYYY-MM-DD"` pair, `NA` for an open end; it crosses Opal as `c("2012-01-01", NA)`.
- `examples/Heron-study/scripts/functions.R` step 4 runs instead of being commented out.

## Non-goals

- `startDate` / `endDate` column arguments: HERON uses the defaults.
- Date encoding for the other pairs (steps 6, 7, 8): they reuse ISO strings or wait for the encoding ADR.
- Generic error wrapping for omopgenerics messages that list `subject_id`s (`checkOverlap()`).
- Disclosure control (user, 2026-11-25). A plain assign pair like the others: it returns nothing. A small-subset
  guard (`nfilter.subset`) was built and then removed: a narrow `dateRange` only discloses once a count or estimate
  about the cohort comes back, and two wide ranges that differ by one person need the aggregate-side rule anyway.
  Decide both with the first aggregate and #16 ([omop-cohort-table.md](../../docs/omop-cohort-table.md),
  "Small subsets").

## Approach

```
ds.trimToDateRange("cdm", "population", as.Date(c("2012-01-01", NA)))
  -> makeAssignWrapper("trimToDateRangeDS") -> assign to `cdm`:
     trimToDateRangeDS(cdm = cdm, cohort = "population", dateRange = c("2012-01-01", NA))
Rock: checkCohortTarget(cdm, cohort); dateRange -> as.Date (ISO only)
      cdm[[cohort]] <- trimToDateRange(cdm[[cohort]], dateRange, cohortId)
```

Opal accepts plain vectors and lists (`c`, `list` come from dsBase) but refuses classed objects: a `Date`, factor or
data.frame deparses to `structure(...)`, which is no DataSHIELD method (tested live on Opal 6.2.2, 2026-11-25).

## Files

- `dsCohortConstructor/Server/R/trimToDateRangeDS.R`, `inst/DATASHIELD`, `tests/testthat/test-trimToDateRangeDS.R`.
- `dsCohortConstructor/Client/R/ds.trimToDateRange.R`, `tests/testthat/test-ds.trimToDateRange.R`.
- `examples/Heron-study/scripts/functions.R`, iteration-9 backlog, `docs/omop-cohort-table.md`.

## Done when

1. New server and client tests pass; no new failures beyond the known red ones.
2. On the local stack, `trimToDateRangeDS` published in Opal and a live `ds.trimToDateRange` call with an `NA` end is
   accepted by Opal's parser.
