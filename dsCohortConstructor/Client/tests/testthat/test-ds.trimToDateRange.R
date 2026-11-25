serverSubjects <- function(cohort) {
  omopgenerics::cohortCount(serverCdm()[[cohort]])$number_subjects
}

test_that("ds.trimToDateRange trims the cohort on the server from a Date range", {
  ds.demographicsCohort("cdm", "to_trim", datasources = conns)
  expect_null(ds.trimToDateRange("cdm", "to_trim", as.Date(c("2019-01-01", NA)), datasources = conns))
  starts <- dplyr::pull(serverCdm()$to_trim, "cohort_start_date")
  expect_true(all(starts >= as.Date("2019-01-01")))
})

test_that("ds.trimToDateRange takes ISO strings and c(NA, NA)", {
  ds.demographicsCohort("cdm", "to_trim", datasources = conns)
  before <- serverSubjects("to_trim")
  ds.trimToDateRange("cdm", "to_trim", c(NA, NA), datasources = conns)
  expect_identical(serverSubjects("to_trim"), before)
  ds.trimToDateRange("cdm", "to_trim", c("2030-01-01", NA), datasources = conns)
  expect_identical(serverSubjects("to_trim"), 0L)
})
