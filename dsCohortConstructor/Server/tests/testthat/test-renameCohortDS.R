populationCdm <- function(...) {
  cdm <- gibleedCdm()
  cdm$population <- suppressMessages(CohortConstructor::demographicsCohort(cdm, "population", ...))
  cdm
}

cohortNames <- function(cohort) {
  omopgenerics::settings(cohort)$cohort_name
}

test_that("renameCohortDS renames the cohort and keeps its records", {
  cdm <- populationCdm()
  out <- renameCohortDS(cdm, "population", "general_population")
  expect_s3_class(out, "cdm_reference")
  expect_identical(cohortNames(out$population), "general_population")
  expect_identical(omopgenerics::cohortCount(out$population)$number_records,
                   omopgenerics::cohortCount(cdm$population)$number_records)
})

test_that("renameCohortDS renames only the cohortId given", {
  cdm <- populationCdm(ageRange = list(c(0, 17), c(18, 150)))
  out <- renameCohortDS(cdm, "population", "adults", cohortId = 2)
  expect_identical(cohortNames(out$population), c("demographics_1", "adults"))
})

test_that("renameCohortDS never touches a CDM table that is not a cohort", {
  expect_error(renameCohortDS(gibleedCdm(), "person", "x"), "person")
})

test_that("renameCohortDS refuses a cohort that does not exist", {
  expect_error(renameCohortDS(populationCdm(), "nope", "x"), "nope")
})
