#' Rename a cohort
#'
#' Server assign method for `ds.renameCohort()`. Runs
#' [CohortConstructor::renameCohort()] on `cdm[[cohort]]`, which validates the
#' names and ids.
#'
#' @param cdm The session's `cdm_reference`.
#' @param cohort Name of an existing cohort table in `cdm`.
#' @param newCohortName New `cohort_name`.
#' @param cohortId `NULL` (every cohort) or the `cohort_definition_id` to rename.
#' @return The updated server-side `cdm_reference`.
#' @export
renameCohortDS <- function(cdm, cohort, newCohortName, cohortId = NULL) {
  dsDarwinHelpers::checkCohortTarget(cdm, cohort)
  cdm[[cohort]] <- CohortConstructor::renameCohort(cdm[[cohort]], newCohortName, cohortId = cohortId)
  cdm
}
