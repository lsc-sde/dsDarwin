test_that("ds.renameCohort renames the cohort on the server", {
  ds.demographicsCohort("cdm", "to_rename", datasources = conns)
  expect_null(ds.renameCohort("cdm", "to_rename", "general_population", datasources = conns))
  expect_identical(omopgenerics::settings(serverCdm()$to_rename)$cohort_name, "general_population")
})
