# AGENTS.md

Entry point for every coding agent working in this repo (Claude Code, opencode, GitHub Copilot, goose).

## What this is

dsDarwin wraps DARWIN EU OMOP R packages for DataSHIELD, so analysts can run them on data they cannot see.
First target: **CohortConstructor**, for the [HERON-UK Characterisation](https://github.com/heron-uk/HERON-UK-Characterisation) study on **Delphi-100k**.

Every wrapped function becomes a pair:

- **Server package**: installed in a Rock R-server image, run by Opal, next to the data. Returns only disclosure-checked results.
- **Client package**: what the analyst calls from their own R session. Sends calls to the server and combines the results.

## Repo layout

```
dsDarwin/
├── CohortConstructor/
│   ├── Client/            # client R package: ds.* functions
│   └── Server/            # server R package: *DS assign/aggregate functions
├── <NextDarwinPackage>/   # same Client/Server pair per wrapped DARWIN package
├── deploy/
│   ├── Tiltfile           # local dev loop on k8s
│   ├── Dockerfile         # (planned) Rock image with the server packages installed
│   ├── yaml/              # (planned) Opal config values and profiles
│   └── k8s/               # Kubernetes manifests
├── examples/              # (planned) runnable analyses, e.g. HERON on Delphi-100k
├── docs/                  # (planned) wrapping guide, CONTRIBUTING.md
├── spec/                  # ADRs, constraints, iteration plans
└── .github/workflows/     # (planned) CI: R CMD check, Rock image build and push
```

Each `Client/` and `Server/` folder is a standalone R package. Build, check and install each one on its own.

## Conventions

- **Package names**: `ds` + DARWIN package name for the server package, plus a `Client` suffix for the client package.
  Example: `dsCohortConstructor` (server) and `dsCohortConstructorClient` (client).
- **Client functions** are named `ds.` + the DARWIN function name and take the same arguments as the DARWIN function.
  Example: `ds.conceptCohort()` mirrors `CohortConstructor::conceptCohort()`.
- **Server functions** are named after the DARWIN function with a `DS` suffix, e.g. `conceptCohortDS()`. Each one is either:
  - **assign**: creates an object on the server (e.g. a cohort table) and returns nothing to the client.
  - **aggregate**: returns a summary that is safe to disclose (e.g. counts above the threshold).
- Opal only allows server functions that are declared in the server package's `inst/DATASHIELD` file, under `AssignMethods:` or `AggregateMethods:`.
  Disclosure settings (`default.nfilter.*`) go under `Options:` in the same file. See `inst/DATASHIELD` in [dsBase](https://github.com/datashield/dsBase) for the format.

## Rules

1. **Spec first.** Read `spec/` before changing behaviour. Record any new decision as an ADR in `spec/adr/` (copy `template.md`) before you implement it.
2. **Disclosure control.** Server functions must never return row-level data to the client. Every aggregate function checks its output against the DataSHIELD disclosure thresholds (`nfilter.*`) before returning it.
3. **TDD.** Write a failing `testthat` test first, then the code that makes it pass.

## Build, check, test

Run these from the repo root, once per package (`CohortConstructor/Server`, `CohortConstructor/Client`):

```sh
Rscript -e 'devtools::document("CohortConstructor/Server")'   # roxygen -> NAMESPACE, man/
Rscript -e 'devtools::test("CohortConstructor/Server")'       # testthat
Rscript -e 'devtools::check("CohortConstructor/Server")'      # R CMD check
Rscript -e 'devtools::install("CohortConstructor/Server")'
```

To test client and server together without an Opal server, use [DSLite](https://datashield.github.io/DSLite/), an in-memory DataSHIELD server.

## Reference docs

Link to these docs, do not copy them into the repo.

**Specs (this repo)**
- [spec/README.md](spec/README.md): what goes where and the naming scheme
- [spec/adr/](spec/adr/): architecture decision records
- [spec/constraints/](spec/constraints/): constraints every change must follow
- [spec/iteration-plans/](spec/iteration-plans/): what is built in each iteration

**Opal / DataSHIELD**
- Opal docs: https://opaldoc.obiba.org/en/latest/
- DataSHIELD admin in Opal: https://opaldoc.obiba.org/en/latest/web-user-guide/administration/datashield.html
- opalr (Opal R client): https://www.obiba.org/opalr/
- DSI (DataSHIELD interface): https://datashield.github.io/DSI/
- DSOpal (DSI driver for Opal): https://datashield.github.io/DSOpal/
- DSLite: https://datashield.github.io/DSLite/
- DataSHIELD wiki: https://wiki.datashield.org/

**DARWIN EU**
- CohortConstructor: https://ohdsi.github.io/CohortConstructor/
- omopgenerics: https://darwin-eu.github.io/omopgenerics/
- CDMConnector: https://darwin-eu.github.io/CDMConnector/
- HERON-UK Characterisation study: https://github.com/heron-uk/HERON-UK-Characterisation
