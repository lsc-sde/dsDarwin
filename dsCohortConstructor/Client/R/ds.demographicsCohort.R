#' Create a demographics-based cohort on each server
#'
#' Calls `demographicsCohortDS()` to create `cdm$<name>` on each server.
#' Optional `NULL` arguments use the server defaults.
#'
#' @param cdm Name of the cdm object on the servers (made by `cdmFromConDS()`).
#' @param name Name of the new cohort table in the server cdm, snake_case.
#' @param ageRange `NULL`, one `c(lower, upper)` age range, or a list of them
#'   (one cohort per range).
#' @param sex `NULL`, `"Both"`, `"Male"` or `"Female"`.
#' @param minPriorObservation `NULL` or days of prior observation required.
#' @param datasources DataSHIELD connections; `NULL` uses the default ones.
#' @return `NULL`, invisibly.
#' @examples
#' \dontrun{
#' # conns holds active study connections with cdm already assigned.
#' ds.demographicsCohort("cdm", "population", ageRange = c(18, 150),
#'                       datasources = conns)
#' }
#' @export
ds.demographicsCohort <- function(cdm = "cdm", name, ageRange = NULL, sex = NULL,
                                  minPriorObservation = NULL, datasources = NULL) {
  if (is.numeric(ageRange)) {
    ageRange <- list(ageRange)
  }
  wrapper <- dsDarwinHelpersClient::makeAssignWrapper("demographicsCohortDS")
  wrapper(
    datasources = datasources,
    newobj = cdm,
    cdm = dsDarwinHelpersClient::AsSymbol(cdm),
    name = name,
    ageRange = if (!is.null(ageRange)) lapply(ageRange, as.numeric),
    sex = sex,
    minPriorObservation = minPriorObservation
  )
}
