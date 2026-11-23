# Server helpers called from inside the dsDarwin *DS functions (no inst/DATASHIELD of their own).
#' Disclosure threshold for counts
#'
#' Reads the threshold the dsBase way: `nfilter.tab`, falling back to
#' `default.nfilter.tab` (spec/constraints/disclosure-control.md). With
#' neither set it stops: no result leaves the server without a threshold.
#'
#' @return The threshold, a single number.
#' @export
nfilterTab <- function() {
  option <- getOption("nfilter.tab", getOption("default.nfilter.tab"))
  if (is.null(option)) {
    cli::cli_abort(c(
      "No disclosure threshold set.",
      i = "Set {.code nfilter.tab} in the Opal DataSHIELD profile."
    ))
  }
  threshold <- suppressWarnings(as.numeric(option))
  if (length(threshold) != 1 || is.na(threshold) || threshold < 1) {
    cli::cli_abort(c(
      "Malformed disclosure threshold {.code nfilter.tab}.",
      x = "Got {.val {option}}; need a single number of at least 1."
    ))
  }
  threshold
}

#' Check where a cohort may be written
#'
#' `cdm` must be a `cdm_reference`, and `name` may be new or an existing
#' cohort, never another CDM table (e.g. `person`).
#'
#' @param cdm The session's `cdm_reference`.
#' @param name Name of the cohort table to write in `cdm`.
#' @return `NULL`, invisibly; stops otherwise.
#' @export
checkCohortTarget <- function(cdm, name) {
  if (!inherits(cdm, "cdm_reference")) {
    cli::cli_abort(c(
      "{.arg cdm} must be a {.cls cdm_reference}.",
      x = "You supplied {.cls {class(cdm)}}."
    ))
  }
  if (name %in% names(cdm) && !inherits(cdm[[name]], "cohort_table")) {
    cli::cli_abort(c(
      "{.arg name} {.val {name}} is a CDM table, not a cohort.",
      i = "Use a new name or an existing cohort."
    ))
  }
  invisible(NULL)
}

#' Apply disclosure control to a table of counts
#'
#' Counts above 0 and below [nfilterTab()] become `NA`, per cell, so one small
#' cohort does not hide the others.
#'
#' @param counts A data frame with `number_records` and `number_subjects`.
#' @return `counts` with small counts replaced by `NA`.
#' @export
applyDisclosureControl <- function(counts) {
  threshold <- nfilterTab()
  for (col in c("number_records", "number_subjects")) {
    x <- counts[[col]]
    x[x > 0 & x < threshold] <- NA
    counts[[col]] <- x
  }
  counts
}
