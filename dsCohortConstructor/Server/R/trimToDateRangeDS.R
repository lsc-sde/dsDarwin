#' Trim a cohort to a date range
#'
#' Server assign method for `ds.trimToDateRange()`. Runs
#' [CohortConstructor::trimToDateRange()] on `cdm[[cohort]]`.
#'
#' @details Disclosure control: none yet, as for every assign pair. A narrow
#'   `dateRange` can leave a cohort with a handful of people; that is guarded
#'   where counts and estimates leave the server, in the aggregate functions
#'   (suppression rule, issue #16), not here.
#'
#' @param cdm The session's `cdm_reference`.
#' @param cohort Name of an existing cohort table in `cdm`.
#' @param dateRange Two `"YYYY-MM-DD"` strings, `NA` for an open end
#'   (`c(NA, NA)` keeps every date).
#' @param cohortId `NULL` (every cohort) or the `cohort_definition_id`s to
#'   trim.
#' @return The updated server-side `cdm_reference`.
#' @export
trimToDateRangeDS <- function(cdm, cohort, dateRange, cohortId = NULL) {
  dsDarwinHelpers::checkCohortTarget(cdm, cohort)


  cdm[[cohort]] <- CohortConstructor::trimToDateRange(
    cdm[[cohort]],
    dateRange = parse_date_range(dateRange),
    cohortId = cohortId
  )
  cdm
}

# For the server passing the as.Date from the client strings
parse_date_range <- function(dateRange) {
  dates <- as.Date(as.character(dateRange), format = "%Y-%m-%d")
  if (length(dates) != 2 || any(is.na(dates) & !is.na(dateRange))) {
    cli::cli_abort(
      "{.arg dateRange} must be two {.code YYYY-MM-DD} dates or {.code NA}."
    )
  }
  dates
}
