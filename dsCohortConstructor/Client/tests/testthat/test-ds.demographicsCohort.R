nativeDemographicsCount <- function(...) {
  cdm <- suppressMessages(omock::mockCdmFromDataset("GiBleed", source = "duckdb"))
  cohort <- suppressMessages(CohortConstructor::demographicsCohort(cdm, "population", ...))
  omopgenerics::cohortCount(cohort)
}

test_that("ds.demographicsCohort runs HERON's population call, counts match native", {
  for (sex in c(TRUE, FALSE)) {
    sexCohort <- if (sex) "Both"
    expect_null(ds.demographicsCohort(
      cdm = "cdm", name = "population", sex = sexCohort, datasources = conns
    ))
    cohort <- serverCdm()$population
    expect_s3_class(cohort, "cohort_table")
    expect_identical(omopgenerics::cohortCount(cohort), nativeDemographicsCount(sex = sexCohort))
  }
})

test_that("ds.demographicsCohort sends ageRange, sex and minPriorObservation", {
  ds.demographicsCohort(
    "cdm", "by_age", ageRange = list(c(0L, 17L), c(18, 150)), sex = "Female",
    minPriorObservation = 365, datasources = conns
  )
  expect_identical(
    omopgenerics::cohortCount(serverCdm()$by_age),
    nativeDemographicsCount(ageRange = list(c(0, 17), c(18, 150)), sex = "Female", minPriorObservation = 365)
  )
})

test_that("ds.demographicsCohort accepts one age range as a bare vector", {
  ds.demographicsCohort("cdm", "one_age", ageRange = c(18, 64), datasources = conns)
  expect_identical(
    omopgenerics::cohortCount(serverCdm()$one_age),
    nativeDemographicsCount(ageRange = list(c(18, 64)))
  )
})
