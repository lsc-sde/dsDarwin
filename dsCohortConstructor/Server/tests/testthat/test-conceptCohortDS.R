test_that("conceptCohortDS adds the cohort to cdm with native counts", {
  cdm <- gibleedCdm()
  out <- conceptCohortDS(cdm, "gi_bleed", 192671, "gibleed")
  expect_s3_class(out, "cdm_reference")
  expect_s3_class(out$gibleed, "cohort_table")
  expect_identical(omopgenerics::settings(out$gibleed)$cohort_name, "gi_bleed")

  native <- CohortConstructor::conceptCohort(
    gibleedCdm(), conceptSet = list(gi_bleed = 192671L), name = "gibleed"
  )
  expect_identical(omopgenerics::cohortCount(out$gibleed), omopgenerics::cohortCount(native))
})

test_that("conceptCohortDS rejects a cdm that is not a cdm_reference", {
  expect_error(conceptCohortDS("cdm", "gi_bleed", 192671, "gibleed"), "cdm_reference")
})

test_that("conceptCohortDS rejects conceptId that is not one positive whole number", {
  cdm <- gibleedCdm()
  for (bad in list("192671", 1.5, c(1, 2), -1, NA_real_)) {
    expect_error(conceptCohortDS(cdm, "gi_bleed", bad, "gibleed"), "conceptId")
  }
})

test_that("conceptCohortDS never replaces a CDM table that is not a cohort", {
  cdm <- gibleedCdm()
  expect_error(conceptCohortDS(cdm, "gi_bleed", 192671, "person"), "person")
  expect_false(inherits(cdm$person, "cohort_table"))
  expect_true("year_of_birth" %in% colnames(cdm$person))
})

test_that("conceptCohortDS may replace an existing cohort", {
  cdm <- conceptCohortDS(gibleedCdm(), "gi_bleed", 192671, "gibleed")
  out <- conceptCohortDS(cdm, "celecoxib", 1118084, "gibleed")
  expect_identical(omopgenerics::settings(out$gibleed)$cohort_name, "celecoxib")
})

test_that("conceptCohortDS: a concept with no records gives an empty cohort, no error", {
  expect_warning(
    out <- conceptCohortDS(gibleedCdm(), "nothing", 1, "empty"),
    "not present"
  )
  expect_identical(omopgenerics::cohortCount(out$empty)$number_subjects, 0L)
})

test_that("inst/DATASHIELD declares conceptCohortDS as an assign method only", {
  dcf <- read.dcf(system.file("DATASHIELD", package = "dsCohortConstructor"))
  expect_match(dcf[, "AssignMethods"], "conceptCohortDS")
  expect_false(any(c("AggregateMethods", "Options") %in% colnames(dcf)))
})
