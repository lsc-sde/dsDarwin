# Iteration 8: server packages found, not listed, in the Rock image

Date: 2026-11-23. Builds on [iteration 6](iteration-6-cohort-constructor-plan.md).
ADR candidates: none (a build script; no change to what crosses the client/server boundary).

## Why

`deploy/Dockerfile` and `.dockerignore` name each server package by path. Every new `ds<DarwinPackage>/Server`
means three hand edits (two `COPY` lines, one allow-list line), plus its CRAN imports in `install.packages()`.
Forget one and the image builds without the package; Opal only finds out at `dsadmin.publish_package()`.

## Goals

- `deploy/scripts/install-server-packages.R <repo root>` finds every `ds*/Server` and `helpers/*/Server` package,
  installs their missing CRAN imports, installs them local dependencies first, and fails unless each one loads.
- The Dockerfile and `.dockerignore` use it with globs: a new server package folder needs no deploy edits.
- The same command runs in CI (future `.github/workflows/`) on any R with the CRAN repo set.

## Non-goals

- Publishing the methods in Opal (`opalr::dsadmin.publish_package()`): needs a running Opal, stays in `examples/`.
- The CI workflow itself; client packages; `renv` pinning (#17).

## Files

- `deploy/scripts/install-server-packages.R` (new).
- `deploy/Dockerfile`: `COPY . ` + the script, replacing the per-package `COPY`/`R CMD INSTALL`.
- `.dockerignore`: `!ds*/Server`, `!helpers/*/Server`, the script.
- `AGENTS.md`: repo layout lists the script.

## Proof

- `docker compose -f deploy/docker/docker-compose.yml build delphi-setup` from a clean image: installs
  `dsDarwinHelpers` before `dsCohortConstructor` (glob order is the reverse) and both load.
