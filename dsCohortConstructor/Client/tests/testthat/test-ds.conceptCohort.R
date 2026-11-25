test_that("ds.conceptCohort builds the cohort on the server, counts match native", {
  expect_null(ds.conceptCohort("cdm", list(gi_bleed = 192671), "gibleed", datasources = conns))
  cohort <- serverCdm()$gibleed
  expect_s3_class(cohort, "cohort_table")
  expect_identical(omopgenerics::settings(cohort)$cohort_name, "gi_bleed")
  expect_identical(omopgenerics::cohortCount(cohort), nativeGibleedCount())
})

test_that("ds.conceptCohort refuses a conceptSet that is not one named concept", {
  for (bad in list(list(a = c(1, 2)), list(1), list(a = 1, b = 2), 192671, list(a = "1"))) {
    expect_error(ds.conceptCohort("cdm", bad, "x", datasources = conns), "conceptSet")
  }
})

test_that("ds.conceptCohort: a name with code is refused before it runs", {
  # DSLite's parser, like Opal's, already rejects the quote; the server check is the second layer.
  expect_error(ds.conceptCohort("cdm", list(a = 192671), "x'); ls(); ('", datasources = conns))
  expect_match(unlist(DSI::datashield.errors()), "Syntax error|snake_case")
})

test_that("ds.conceptCohort: a name that is not snake_case is refused by the server", {
  expect_error(ds.conceptCohort("cdm", list(a = 192671), "GiBleed", datasources = conns))
  expect_match(unlist(DSI::datashield.errors()), "snake_case")
})
