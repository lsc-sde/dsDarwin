# Client half of every dsDarwin wrapper: ds.foo() -> make*Wrapper("fooDS") -> DSI -> Opal -> fooDS() on Rock.
#' Mark a value as a server-side object name
#'
#' Sent unquoted, so the server evaluates it (e.g. `cdm`, `cdm$gibleed`).
#'
#' @param x A single string: a server object name.
#' @return `x` with class `AsSymbol`.
#' @export
AsSymbol <- function(x) {
  structure(x, class = "AsSymbol")
}

#' Build a DataSHIELD call from a server function name and arguments
#'
#' @param fnName The server function name, e.g. `"conceptCohortDS"`.
#' @param ... Arguments: [AsSymbol()] values are sent as object names, the rest as values.
#' @return An R call, e.g. `conceptCohortDS(cdm = cdm, name = "gibleed")`.
#' @export
buildDSCall <- function(fnName, ...) {
  arguments <- lapply(list(...), function(value) {
    if (inherits(value, "AsSymbol")) {
      return(str2lang(unclass(value)))
    }
    value
  })

  as.call(c(as.name(fnName), arguments))
}

#' Find the DataSHIELD connections to use
#'
#' @param datasources A list of `DSConnection`s, or `NULL` for the default ones.
#' @return The connections.
#' @export
findConnections <- function(datasources = NULL) {
  if (is.null(datasources)) {
    datasources <- DSI::datashield.connections_find()
  }
  if (!is.list(datasources) || !length(datasources) ||
      !all(vapply(datasources, methods::is, logical(1), "DSConnection"))) {
    stop("`datasources` must be a list of DSConnection objects.", call. = FALSE)
  }
  datasources
}

#' Create an aggregate wrapper
#'
#' @param serverFn The server aggregate function name.
#' @return A function `(datasources, ...)`.
#' @export
makeAggregateWrapper <- function(serverFn) {
  function(datasources = NULL, ...) {
    DSI::datashield.aggregate(conns = findConnections(datasources), expr = buildDSCall(serverFn, ...))
  }
}

#' Create an assign wrapper
#'
#' @param serverFn The server assign function name.
#' @return A function `(datasources, newobj, ...)`.
#' @export
makeAssignWrapper <- function(serverFn) {
  function(datasources = NULL, newobj, ...) {
    DSI::datashield.assign.expr(
      conns = findConnections(datasources),
      symbol = newobj,
      expr = buildDSCall(serverFn, ...)
    )
    invisible(NULL)
  }
}
