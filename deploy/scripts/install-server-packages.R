# Installs every dsDarwin server package under a repo root (ds*/Server,
# helpers/*/Server): missing CRAN imports first, then the packages, local
# dependencies before the packages that import them. Fails unless all load.
# Usage: Rscript deploy/scripts/install-server-packages.R [repo root]

find_server_packages <- function(root) {
  descriptions <- Sys.glob(file.path(
    root,
    c("ds*/Server/DESCRIPTION", "helpers/*/Server/DESCRIPTION")
  ))
  if (length(descriptions) == 0) {
    cli::cli_abort(c(
      "No server packages found.",
      x = "Nothing matches {.path ds*/Server} or {.path helpers/*/Server}.",
      i = "Root: {.path {normalizePath(root, mustWork = FALSE)}}."
    ))
  }
  paths <- dirname(descriptions)
  names(paths) <- vapply(descriptions, read_package_name, character(1))
  paths
}

read_package_name <- function(description) {
  read.dcf(description, "Package")[[1]]
}

read_dependencies <- function(path) {
  fields <- read.dcf(
    file.path(path, "DESCRIPTION"),
    c("Depends", "Imports", "LinkingTo")
  )
  dependencies <- unlist(strsplit(fields[!is.na(fields)], ","))
  dependencies <- trimws(sub("\\(.*", "", dependencies))
  setdiff(dependencies, c("R", ""))
}

install_package <- function(name, path) {
  r_bin <- file.path(R.home("bin"), "R")
  status <- system2(r_bin, c("CMD", "INSTALL", shQuote(path)))
  if (status != 0) {
    cli::cli_abort(c(
      "Failed to install {.pkg {name}}.",
      x = "{.code R CMD INSTALL} exited with status {status}.",
      i = "Source: {.path {path}}."
    ))
  }
}

install_in_dependency_order <- function(paths, dependencies) {
  todo <- names(paths)
  while (length(todo) > 0) {
    is_ready <- !vapply(
      dependencies[todo],
      function(deps) any(deps %in% todo),
      logical(1)
    )
    if (!any(is_ready)) {
      cli::cli_abort(c(
        "Circular dependency between server packages.",
        x = "Each of {.pkg {todo}} waits on another."
      ))
    }
    for (name in todo[is_ready]) {
      install_package(name, paths[[name]])
    }
    todo <- todo[!is_ready]
  }
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  root <- if (length(args) > 0) args[[1]] else "."
  paths <- find_server_packages(root)
  dependencies <- lapply(paths, read_dependencies)

  missing <- setdiff(
    unlist(dependencies),
    c(names(paths), rownames(installed.packages()))
  )
  if (length(missing) > 0) {
    install.packages(missing)
  }

  install_in_dependency_order(paths, dependencies)

  is_loadable <- vapply(
    names(paths),
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
  if (!all(is_loadable)) {
    cli::cli_abort(c(
      "Server packages installed but not loadable.",
      x = "{.pkg {names(paths)[!is_loadable]}} failed to load."
    ))
  }
  cli::cli_alert_success("Server packages installed: {.pkg {names(paths)}}.")
}

main()
