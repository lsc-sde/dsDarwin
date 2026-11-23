#' Create a concept-based cohort (server side)
#'
#' Assign method behind `ds.conceptCohort()`. Runs
#' [CohortConstructor::conceptCohort()] on the session's `cdm` and returns the
#' `cdm` with the cohort as `cdm[[name]]`
#' Opal passes only simple values, so the codelist arrives as one name and one id.
#'
#' @param cdm The session's `cdm_reference` (made by `cdmFromConDS()`).
#' @param conceptName Codelist name, snake_case; becomes the `cohort_name`.
#' @param conceptId One OMOP concept id, a positive whole number.
#' @param name Name of the cohort table in `cdm`, snake_case. May replace an
#'   existing cohort, never another CDM table.
#' @return The updated `cdm_reference`.
#' @export
conceptCohortDS <- function(cdm, conceptName, conceptId, name) {
  dsDarwinHelpers::checkCohortTarget(cdm, name)


  # TODO: conceptName and name are not validated yet.
  if (!is.numeric(conceptId) || length(conceptId) != 1 || is.na(conceptId) ||
    conceptId <= 0 || conceptId != round(conceptId)) {
    stop("`conceptId` must be one positive whole number.", call. = FALSE)
  }

  conceptSet <- list(as.integer(conceptId)) |>
    stats::setNames(conceptName) |>
    omopgenerics::newCodelist()
  cdm[[name]] <- CohortConstructor::conceptCohort(cdm, conceptSet, name = name)
  cdm
}

