# Conventions

Naming and registration rules for every wrapped DARWIN package. Rationale: [ADR-0002](../adr/0002-package-and-function-naming.md).

- **Package names**: `ds` + DARWIN package name for the server package, plus a `Client` suffix for the client package.
  Example: `dsCohortConstructor` (server) and `dsCohortConstructorClient` (client).
- **Client functions** are named `ds.` + the DARWIN function name and take the same arguments as the DARWIN function.
  Example: `ds.conceptCohort()` mirrors `CohortConstructor::conceptCohort()`.
- **Server functions** are named after the DARWIN function with a `DS` suffix, e.g. `conceptCohortDS()`. Each one is either:
  - **assign**: creates an object on the server (e.g. a cohort table) and returns nothing to the client.
  - **aggregate**: returns a summary that is safe to disclose (e.g. counts above the threshold).
- Opal only allows server functions that are declared in the server package's `inst/DATASHIELD` file, under `AssignMethods:` or `AggregateMethods:`.
  See `inst/DATASHIELD` in [dsBase](https://github.com/datashield/dsBase) for the format. Disclosure thresholds: [disclosure-control.md](disclosure-control.md).
