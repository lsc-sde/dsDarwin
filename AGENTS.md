# AGENTS.md

Entry point for every coding agent working in this repo (Claude Code, opencode, GitHub Copilot, goose).

## What this is

dsDarwin wraps DARWIN EU OMOP R packages for DataSHIELD, so analysts can run them on data they cannot see.
First target: **CohortConstructor**, for the [HERON-UK Characterisation](https://github.com/heron-uk/HERON-UK-Characterisation) study on **Delphi-100k**.

Delphi-100k is a synthetic OMOP CDM 5.4 shipped by omock (`omock::mockCdmFromDataset("delphi-100k_5.4", source = "duckdb")`).
It is the first dataset, not the target: the same packages must run on any OMOP CDM, so no Delphi-specific schemas, table names or concept IDs in package code.

Every wrapped function becomes a pair:

- **Server package**: installed in a Rock R-server image, run by Opal, next to the data. Returns only disclosure-checked results.
- **Client package**: what the analyst calls from their own R session. Sends calls to the server and combines the results.

## Repo layout

```
dsDarwin/
├── .agents/skills/        # shared agent skills; .claude/skills symlinks here
├── CohortConstructor/
│   ├── Client/            # (not scaffolded yet) client R package: ds.* functions
│   └── Server/            # (not scaffolded yet) server R package: *DS assign/aggregate functions
├── <NextDarwinPackage>/   # same Client/Server pair per wrapped DARWIN package
├── deploy/
│   ├── Tiltfile           # (placeholder) local dev loop on k8s
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

Package and function naming, assign vs aggregate, and `inst/DATASHIELD` registration: see [spec/constraints/conventions.md](spec/constraints/conventions.md).

## Rules

1. **Spec first.** Read `spec/` before changing behaviour.
   Write an ADR in `spec/adr/` (copy `template.md`) only for a decision that meets the [ADR threshold](spec/README.md#when-to-write-an-adr); most iterations need none or one. If unsure, don't write one: note the choice in the iteration plan or PR and let a human decide.
   Agent-written ADRs stay `Proposed`, at most one per PR, and name the threshold they meet. Only a human sets `Accepted`.
2. Read the existing constraints to follow the conventions that must be followed for this project [spec/constraints]
3. Every agent: before coding, write `spec/iteration-plans/iteration-N-<slug>-plan.md` (naming in [spec/README.md](spec/README.md)) and list any ADR candidates in it.
   With superpowers, save `brainstorming` designs and `writing-plans` plans there, not in `docs/superpowers/`.
3. **TDD.** Write a failing `testthat` test first before writing the implementation code. For a bug or regression, first add a test that reproduces it, then fix it; the test stays so it can't come back.
   Unit tests use the omock `GiBleed` CDM (6 MB); Delphi-100k (1.5 GB) is for end-to-end runs.

## Build, check, test

Run these from the repo root, once per package (`CohortConstructor/Server`, `CohortConstructor/Client`):

```sh
Rscript -e 'devtools::document("CohortConstructor/Server")'   # roxygen -> NAMESPACE, man/
Rscript -e 'devtools::test("CohortConstructor/Server")'       # testthat
Rscript -e 'devtools::check("CohortConstructor/Server")'      # R CMD check
Rscript -e 'devtools::install("CohortConstructor/Server")'
```


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
- omock (mock and synthetic CDMs, incl. Delphi-100k): https://ohdsi.github.io/omock/
- Also used by HERON: [OmopSketch](https://ohdsi.github.io/OmopSketch/), [CohortCharacteristics](https://darwin-eu.github.io/CohortCharacteristics/), [PatientProfiles](https://darwin-eu.github.io/PatientProfiles/), [OmopConstructor](https://ohdsi.github.io/OmopConstructor/)
- HERON-UK Characterisation study: https://github.com/heron-uk/HERON-UK-Characterisation
