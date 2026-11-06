# ADR-0002: Package and function naming

**Status:** Accepted
**Date:** 2026-10-26

## Context

dsDarwin will wrap many DARWIN EU packages, each as a client/server pair.
DataSHIELD users and agents already know the dsBase / dsBaseClient naming convention.

## Decision

Follow the DataSHIELD convention, named after the wrapped DARWIN package:

| What | Name | Example |
|---|---|---|
| Server package | `ds` + DARWIN package | `dsCohortConstructor` |
| Client package | `ds` + DARWIN package + `Client` | `dsCohortConstructorClient` |
| Client function | `ds.` + DARWIN function, same arguments | `ds.conceptCohort()` |
| Server function | DARWIN function + `DS`, declared in `inst/DATASHIELD` as assign or aggregate | `conceptCohortDS()` |

## Consequences

- Names are predictable: from any DARWIN function you can tell its client and server names, and the DARWIN docs map one-to-one.
- Package names get long.
