#' Create a demographics cohort
#'
#' Server assign method for `ds.demographicsCohort()`. Runs
#' [CohortConstructor::demographicsCohort()] with its defaults for `NULL` inputs.
#'
#' @param cdm The session's `cdm_reference`.
#' @param name Table name. May replace an existing cohort.
#' @param ageRange List of `c(lower, upper)` age pairs, one per cohort.
#' @param sex One of `"Both"`, `"Male"` or `"Female"`.
#' @param minPriorObservation Minimum prior observation in whole days (>= 0).
#' @return The updated server-side `cdm_reference` with the cohort at `cdm[[name]]`.
#' @export
demographicsCohortDS <- function(cdm, name, ageRange = NULL, sex = NULL, minPriorObservation = NULL) {
  dsDarwinHelpers::checkCohortTarget(cdm, name)

  # Need to add the utilised validation for the values

  cdm[[name]] <- CohortConstructor::demographicsCohort(
    cdm, name,
    ageRange = ageRange, sex = sex, minPriorObservation = minPriorObservation
  )
  cdm
}
