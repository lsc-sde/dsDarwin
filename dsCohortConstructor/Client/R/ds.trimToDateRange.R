#' Trim a cohort to a date range on each server
#'
#' Client side of [CohortConstructor::trimToDateRange()]: each server trims the
#' cohort in its own `cdm$<cohort>`, moving start and end dates into
#' `dateRange` and dropping records outside it.
#'
#' @details Sends an **assign** request; the updated cdm is stored back under
#'   `cdm`. Dates cross Opal as `"YYYY-MM-DD"` strings, because a `Date`
#'   object is not accepted by Opal's call parser.
#'   Server function called: \code{trimToDateRangeDS}
#'
#' @param cdm Name of the cdm object on the servers (made by `cdmFromConDS()`).
#' @param cohort Name of the cohort table in the server cdm.
#' @param dateRange Two dates (`Date` or `"YYYY-MM-DD"`), `NA` for an open end.
#' @param cohortId `NULL` (every cohort in the table) or one
#'   `cohort_definition_id`.
#' @param datasources DataSHIELD connections; `NULL` uses the default ones.
#' @return `NULL`, invisibly. Nothing comes back from the servers.
#' @examples
#' \dontrun{
#' # conns holds active study connections with cdm$population already built.
#' ds.trimToDateRange(
#'   "cdm",
#'   cohort = "population",
#'   dateRange = as.Date(c("2012-01-01", NA)),
#'   datasources = conns
#' )
#' }
#' @export
ds.trimToDateRange <- function(cdm = "cdm",
                               cohort,
                               dateRange,
                               cohortId = NULL,
                               datasources = NULL) {
  dateRange <- as.character(dateRange)
  if (all(is.na(dateRange))) {
    dateRange <- as.logical(dateRange)
  }


  wrapper <- dsDarwinHelpersClient::makeAssignWrapper("trimToDateRangeDS")
  wrapper(
    datasources = datasources,
    newobj = cdm,
    cdm = dsDarwinHelpersClient::AsSymbol(cdm),
    cohort = cohort,
    dateRange = dateRange,
    cohortId = cohortId
  )
}
