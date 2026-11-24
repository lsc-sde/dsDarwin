#' Create a demographics cohort
#'
#' Server assign method for `ds.demographicsCohort()`. Runs
#' [CohortConstructor::demographicsCohort()] with its defaults for `NULL` inputs.
#'
#' @param cdm The session's `cdm_reference`.
#' @param name Snake_case table name. May replace an existing cohort.
#' @param ageRange A `c(lower, upper)` age pair, or a list of pairs, one per cohort.
#' @param sex One of `"Both"`, `"Male"` or `"Female"`.
#' @param minPriorObservation Minimum prior observation in whole days (>= 0).
#' @return The updated server-side `cdm_reference` with the cohort at `cdm[[name]]`.
#' @export
demographicsCohortDS <- function(cdm,
                                 name,
                                 ageRange = NULL,
                                 sex = NULL,
                                 minPriorObservation = NULL) {
  ageRange <- parametersValidation(name, ageRange, sex, minPriorObservation)
  dsDarwinHelpers::checkCohortTarget(cdm, name)

  cdm[[name]] <- CohortConstructor::demographicsCohort(
    cdm,
    name,
    ageRange = ageRange,
    sex = sex,
    minPriorObservation = minPriorObservation
  )
  cdm
}

parametersValidation <- function(name, ageRange, sex, minPriorObservation) {
  if (is.numeric(ageRange)) {
    ageRange <- list(ageRange)
  }

  omopgenerics::assertCharacter(name, length = 1, minNumCharacter = 1)
  omopgenerics::validateNameArgument(name, validation = "error")
  omopgenerics::validateAgeGroupArgument(
    ageRange,
    overlap = TRUE,
    empty = FALSE,
    nm = "ageRange"
  )
  omopgenerics::assertChoice(
    sex,
    choices = c("Both", "Male", "Female"),
    length = 1,
    null = TRUE
  )
  omopgenerics::assertNumeric(
    minPriorObservation,
    integerish = TRUE,
    min = 0,
    length = 1,
    null = TRUE
  )

  ageRange
}
