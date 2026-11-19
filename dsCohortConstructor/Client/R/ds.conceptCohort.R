#' Create a concept-based cohort on each server
#'
#' Client side of [CohortConstructor::conceptCohort()]. Sends
#' `conceptCohortDS(cdm, conceptName, conceptId, name)` (package
#' dsCohortConstructor) as an **assign** request: each server builds the cohort
#' from its own data and stores the updated cdm back under `cdm`, with the
#' cohort as `cdm$<name>`. Nothing comes back to the analyst.
#'
#' Opal only accepts simple argument values, so for now `conceptSet` holds one
#' codelist with one concept id.
#'
#' @param cdm Name of the cdm object on the servers (made by `cdmFromConDS()`).
#' @param conceptSet A named list with one concept id, e.g.
#'   `list(gi_bleed = 192671)`. The name becomes the `cohort_name`.
#' @param name Name of the new cohort table in the cdm, snake_case.
#' @param datasources DataSHIELD connections; `NULL` uses the default ones.
#' @return `NULL`, invisibly.
#' @examples
#' \dontrun{
#' builder <- DSI::newDSLoginBuilder()
#' builder$append(
#'   server = "study1", url = "https://opal1.example.org",
#'   user = "analyst", password = "...", driver = "OpalDriver"
#' )
#' builder$append(
#'   server = "study2", url = "https://opal2.example.org",
#'   user = "analyst", password = "...", driver = "OpalDriver"
#' )
#' conns <- DSI::datashield.login(builder$build())
#' DSI::datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))
#' ds.conceptCohort("cdm", list(gi_bleed = 192671), "gibleed", datasources = conns)
#' DSI::datashield.aggregate(conns, quote(classDS("cdm$gibleed"))) # "cohort_table" (dsBase)
#' DSI::datashield.logout(conns)
#' }
#' @export
ds.conceptCohort <- function(cdm = "cdm", conceptSet, name, datasources = NULL) {
  wrapper <- dsDarwinHelpersClient::makeAssignWrapper("conceptCohortDS")
  wrapper(
    datasources = datasources,
    newobj = cdm,
    cdm = dsDarwinHelpersClient::AsSymbol(cdm),
    conceptName = names(conceptSet),
    conceptId = conceptSet[[1]], #For now only one
    name = name
  )
}
