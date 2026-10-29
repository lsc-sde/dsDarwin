# ADR-0001: Target Opal only

**Status:** Accepted
**Date:** 2026-10-26

## Context

DataSHIELD server packages can run on two platforms: Opal (with a Rock R server)
The first study, HERON-UK Characterisation on Delphi-100k, runs on Opal, and `deploy/` builds a Rock image for it.
Supporting both platforms would double the deployment, testing and documentation work.

## Decision

Target Opal with Rock only. Test client and server together locally with DSLite.

## Consequences

- One deploy path (Rock image), one set of client docs (opalr, DSOpal), simpler CI.
- Armadillo is not supported or tested.
- Server functions use standard DataSHIELD mechanisms (`inst/DATASHIELD`)