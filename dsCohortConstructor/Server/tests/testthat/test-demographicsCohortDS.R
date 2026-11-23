nativeDemographicsCount <- function(...) {
  cohort <- suppressMessages(CohortConstructor::demographicsCohort(gibleedCdm(), "population", ...))
  omopgenerics::cohortCount(cohort)
}

test_that("demographicsCohortDS adds the cohort to cdm with native counts", {
  cases <- list(
    list(),
    list(sex = "Female"),
    list(minPriorObservation = 365),
    list(ageRange = list(c(0, 17), c(18, 150)))
  )
  for (args in cases) {
    out <- suppressMessages(do.call(demographicsCohortDS, c(list(gibleedCdm(), "population"), args)))
    expect_s3_class(out, "cdm_reference")
    expect_s3_class(out$population, "cohort_table")
    expect_identical(omopgenerics::cohortCount(out$population), do.call(nativeDemographicsCount, args))
  }
})

test_that("demographicsCohortDS rejects a bad sex", {
  for (bad in list("both", c("Male", "Female"), 1, NA_character_)) {
    expect_error(demographicsCohortDS(gibleedCdm(), "population", sex = bad), "sex")
  }
})

test_that("demographicsCohortDS rejects a bad minPriorObservation", {
  for (bad in list(-1, 1.5, c(1, 2), "365", NA_real_)) {
    expect_error(demographicsCohortDS(gibleedCdm(), "population", minPriorObservation = bad), "minPriorObservation")
  }
})

test_that("demographicsCohortDS rejects a bad ageRange", {
  for (bad in list(c(0, 17), list(c(17, 0)), list(c(-1, 5)), list(c(0, NA)), list(c(0, 1, 2)), list("0-17"))) {
    expect_error(demographicsCohortDS(gibleedCdm(), "population", ageRange = bad), "ageRange")
  }
})

test_that("demographicsCohortDS never replaces a CDM table that is not a cohort", {
  expect_error(demographicsCohortDS(gibleedCdm(), "person"), "person")
})
