#' Rename a cohort on each server
#'
#' Client side of [CohortConstructor::renameCohort()]: each server renames the
#' cohort in its own `cdm$<cohort>`.
#'
#' @details Sends an **assign** request; the updated cdm is stored back under
#'   `cdm`. One new name per call.
#'   Server function called: \code{renameCohortDS}
#'
#' @param cdm Name of the cdm object on the servers (made by `cdmFromConDS()`).
#' @param cohort Name of the cohort table in the server cdm.
#' @param newCohortName New cohort name, snake_case.
#' @param cohortId `NULL` (every cohort in the table) or one `cohort_definition_id`.
#' @param datasources DataSHIELD connections; `NULL` uses the default ones.
#' @return `NULL`, invisibly. Nothing comes back from the servers.
#' @export
ds.renameCohort <- function(cdm = "cdm", cohort, newCohortName, cohortId = NULL, datasources = NULL) {
  wrapper <- dsDarwinHelpersClient::makeAssignWrapper("renameCohortDS")
  wrapper(
    datasources = datasources,
    newobj = cdm,
    cdm = dsDarwinHelpersClient::AsSymbol(cdm),
    cohort = cohort,
    newCohortName = newCohortName,
    cohortId = cohortId
  )
}
