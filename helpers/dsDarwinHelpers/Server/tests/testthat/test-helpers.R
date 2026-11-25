test_that("nfilterTab reads nfilter.tab first", {
  withr::local_options(nfilter.tab = 5, default.nfilter.tab = 3)
  expect_equal(nfilterTab(), 5)
})

test_that("nfilterTab falls back to default.nfilter.tab", {
  withr::local_options(nfilter.tab = NULL, default.nfilter.tab = 3)
  expect_equal(nfilterTab(), 3)
})

test_that("nfilterTab fails closed when no threshold is set", {
  withr::local_options(nfilter.tab = NULL, default.nfilter.tab = NULL)
  expect_error(nfilterTab(), "threshold")
})

test_that("applyDisclosureControl hides counts between 0 and the threshold", {
  withr::local_options(nfilter.tab = 5)
  counts <- data.frame(number_records = c(0L, 2L, 10L), number_subjects = c(0L, 2L, 7L))
  out <- applyDisclosureControl(counts)
  expect_identical(out$number_records, c(0L, NA, 10L))
  expect_identical(out$number_subjects, c(0L, NA, 7L))
})

test_that("applyDisclosureControl hides any count-like numeric column, keeps the rest", {
  withr::local_options(nfilter.tab = 5)
  counts <- data.frame(cohort_definition_id = 1:2, n_subjects = c(2, 9), Record_Count = c(3L, 0L), label = "a")
  out <- applyDisclosureControl(counts)
  expect_identical(out$cohort_definition_id, 1:2)
  expect_identical(out$n_subjects, c(NA, 9))
  expect_identical(out$Record_Count, c(NA, 0L))
})

test_that("applyDisclosureControl suppresses a summarised_result with nfilter.tab, linked estimates too", {
  withr::local_options(nfilter.tab = 5)
  result <- omopgenerics::newSummarisedResult(
    data.frame(
      result_id = 1L, cdm_name = "mock", group_name = "cohort_name", group_level = c("a", "a", "b", "b"),
      strata_name = "overall", strata_level = "overall",
      variable_name = c("number subjects", "age", "number subjects", "age"), variable_level = NA_character_,
      estimate_name = c("count", "mean", "count", "mean"), estimate_type = c("integer", "numeric", "integer", "numeric"),
      estimate_value = c("3", "40", "50", "41"), additional_name = "overall", additional_level = "overall"
    ),
    settings = data.frame(result_id = 1L, result_type = "test", package_name = "test", package_version = "1")
  )
  out <- applyDisclosureControl(result)
  expect_identical(out$estimate_value, c("-", "-", "50", "41"))
  expect_equal(omopgenerics::settings(out)$min_cell_count, "5")
})

test_that("applyDisclosureControl refuses anything that is not a table", {
  withr::local_options(nfilter.tab = 5)
  expect_error(applyDisclosureControl(c(n = 2)), "summarised_result")
})

test_that("nfilterTab fails closed on a malformed threshold", {
  for (bad in list(NA, "", "abc", c(3, 10), 0)) {
    withr::local_options(nfilter.tab = bad)
    expect_error(nfilterTab(), "threshold")
  }
})

test_that("nfilterTab accepts a threshold set as a string, as Opal options are", {
  withr::local_options(nfilter.tab = "5")
  expect_equal(nfilterTab(), 5)
})

test_that("checkCohortTarget accepts a new or cohort name, refuses a non-cdm or a CDM table", {
  cdm <- structure(
    list(person = data.frame(), old = structure(data.frame(), class = c("cohort_table", "data.frame"))),
    class = "cdm_reference"
  )
  expect_silent(checkCohortTarget(cdm, "new"))
  expect_silent(checkCohortTarget(cdm, "old"))
  expect_error(checkCohortTarget(cdm, "person"), "CDM table")
  expect_error(checkCohortTarget(unclass(cdm), "new"), "cdm_reference")
})
