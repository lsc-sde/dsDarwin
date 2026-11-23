# Installs every dsDarwin server package under a repo root (ds*/Server,
# helpers/*/Server): missing CRAN imports first, then the packages, local
# dependencies before the packages that import them. Fails unless all load.
# Usage: Rscript deploy/scripts/install-server-packages.R [repo root]
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else "."

paths <- dirname(Sys.glob(file.path(root, c("ds*/Server/DESCRIPTION", "helpers/*/Server/DESCRIPTION"))))
if (!length(paths)) stop("no server packages under ", normalizePath(root, mustWork = FALSE))
names(paths) <- vapply(paths, function(p) read.dcf(file.path(p, "DESCRIPTION"), "Package")[[1]], "")

deps <- lapply(paths, function(p) {
  fields <- read.dcf(file.path(p, "DESCRIPTION"), c("Depends", "Imports", "LinkingTo"))
  setdiff(trimws(sub("\\(.*", "", unlist(strsplit(fields[!is.na(fields)], ",")))), c("R", ""))
})

missing <- setdiff(unlist(deps), c(names(paths), rownames(installed.packages())))
if (length(missing)) install.packages(missing)

todo <- names(paths)
while (length(todo)) {
  ready <- todo[!vapply(deps[todo], function(d) any(d %in% todo), logical(1))]
  if (!length(ready)) stop("circular dependency between: ", toString(todo))
  for (p in ready) {
    if (system2(file.path(R.home("bin"), "R"), c("CMD", "INSTALL", shQuote(paths[[p]]))) != 0) {
      stop("R CMD INSTALL failed: ", p)
    }
  }
  todo <- setdiff(todo, ready)
}

loaded <- vapply(names(paths), requireNamespace, logical(1), quietly = TRUE)
if (!all(loaded)) stop("installed but not loadable: ", toString(names(paths)[!loaded]))
message("server packages installed: ", toString(names(paths)))
