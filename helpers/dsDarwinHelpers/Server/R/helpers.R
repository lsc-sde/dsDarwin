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
  #Getting threshold from the settings of opal
  threshold <- getOption("nfilter.tab", getOption("default.nfilter.tab"))
  if (is.null(threshold)) {
    stop("No disclosure threshold set (nfilter.tab).", call. = FALSE)
  }
  threshold
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
