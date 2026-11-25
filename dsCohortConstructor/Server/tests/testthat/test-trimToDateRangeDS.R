populationCdm <- function() {
  cdm <- gibleedCdm()
  cdm$population <- suppressMessages(CohortConstructor::demographicsCohort(cdm, "population"))
  cdm
}

subjects <- function(cohort) {
  omopgenerics::cohortCount(cohort)$number_subjects
}

test_that("trimToDateRangeDS trims like CohortConstructor::trimToDateRange", {
  out <- trimToDateRangeDS(populationCdm(), "population", c("2019-01-01", NA))
  native <- suppressMessages(CohortConstructor::trimToDateRange(
    populationCdm()$population, as.Date(c("2019-01-01", NA))
  ))
  expect_s3_class(out, "cdm_reference")
  expect_identical(subjects(out$population), subjects(native))
  starts <- dplyr::pull(out$population, "cohort_start_date")
  expect_true(all(starts >= as.Date("2019-01-01")))
})

test_that("trimToDateRangeDS with c(NA, NA) keeps everyone", {
  cdm <- populationCdm()
  out <- trimToDateRangeDS(cdm, "population", c(NA, NA))
  expect_identical(subjects(out$population), subjects(cdm$population))
})

test_that("trimToDateRangeDS allows an empty result", {
  out <- trimToDateRangeDS(populationCdm(), "population", c("2030-01-01", NA))
  expect_identical(subjects(out$population), 0L)
})

test_that("trimToDateRangeDS refuses malformed date ranges", {
  expect_error(trimToDateRangeDS(populationCdm(), "population", c("01/01/2019", NA)), "YYYY-MM-DD")
  expect_error(trimToDateRangeDS(populationCdm(), "population", "2019-01-01"), "dateRange")
  expect_error(trimToDateRangeDS(populationCdm(), "population", c("2012-01-01", "2015-13-01")), "YYYY-MM-DD")
})

test_that("trimToDateRangeDS never touches a CDM table that is not a cohort", {
  expect_error(trimToDateRangeDS(gibleedCdm(), "person", c(NA, NA)), "person")
})
