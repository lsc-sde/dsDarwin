# ADR-0003: Server functions reach the OMOP CDM through an Opal resource

**Status:** Proposed
**Date:** 2026-11-09

ADR threshold met: sets the data-access and security posture (who can point a server function at which database, and where credentials live).

## Context

CohortConstructor and the other DARWIN packages work on a `cdm_reference` built by `CDMConnector::cdmFromCon()` from a live DBI connection.
They need about 40 linked OMOP tables (vocabularies run to millions of rows) and a writable schema for the cohort tables they create.

Opal offers two ways to serve data to Rock:

- **Tables**: imported into an Opal data database (Mongo, MySQL, MariaDB, Postgres). Opal owns the storage and pushes data frames into the R session.
- **Resources** ([resourcer](https://github.com/obiba/resourcer)): a stored pointer (URL, credentials, options) to data that stays where it is. `DSI::datashield.assign.resource()` hands the server a `ResourceClient`; the server opens the connection itself.

A third option, a DBI connection opened inside a `*DS` function, would put the host and credentials in package code, env vars or analyst arguments.

## Decision

The CDM lives in its own database, outside Opal's storage, and is registered in Opal as a **resource**.
The analyst assigns it with `datashield.assign.resource()` and only ever sees the resource name.
A server function turns the resource connection into a `cdm` with `CDMConnector::cdmFromCon()`; the CDM schema and the write schema/prefix come from the resource definition set by the Opal admin, not from analyst arguments.

For the local HERON test the CDM is a DuckDB file (team decision; [iteration 2](../iteration-plans/iteration-2-delphi-data-plan.md)).
A DuckDB file accepts one writer or many readers, so every session attaches the CDM `READ_ONLY` into its own in-memory DuckDB and writes cohorts there.
Server databases (Postgres, SQL Server) use the resource's connection directly and a results schema for cohorts.

Which resolver provides the resource type is still open:
[dsOMOP](https://github.com/isglobal-brge/dsOMOP)'s `omop.dbi.db` (Opal form, many engines, but its DuckDB connection opens read-write)
or a small resolver of our own.

## Consequences

- Credentials stay in Opal; Opal permissions on the resource decide who can use which CDM.
- The analyst cannot name a schema or table, so cannot aim a `*DS` function at raw tables.
- Same mechanism for Delphi-100k locally and a real site's CDM: only the resource definition changes.
- Opal's tables-import route (and its data databases) is not used for OMOP.
- resourcer has no built-in DuckDB resolver: either dsOMOP (bypassing its read-write connection) or our own `ResourceResolver`.
- Rock needs `resourcer` plus the DBI driver for the engine installed in its image.
- With DuckDB, cohort tables live in session memory and vanish at logout, like any DataSHIELD session object.
