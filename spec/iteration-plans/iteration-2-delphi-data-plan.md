# Iteration 2: Delphi-100k into the local stack (DuckDB)

Issue: #14 (part of epic #11). Date: 2026-11-09. Builds on [iteration 1](iteration-1-local-stack-plan.md).
ADR candidate: [ADR-0003](../adr/0003-cdm-through-opal-resource.md) (Proposed), updated by this iteration.

## Why

Iteration 1 runs Opal + Rock with no OMOP data. Before wrapping CohortConstructor, Rock must see Delphi-100k.
This iteration only brings the data in and proves Rock can read it. No resource, no `*DS` function yet.

## Architecture

```
deploy/Dockerfile ──build once──▶ image dsdarwin/rock:dev  (rock-base + duckdb + CDMConnector)
                                     │
               ┌─────────────────────┴─────────────────────┐
               ▼                                           ▼
   delphi-setup (one-off, exits)                  rock (Rock R server)
   CDMConnector::eunomiaDir("delphi-100k")       mounts omop-data READ-ONLY
   omop-data:/data read-write                    per session: in-memory DuckDB (writable,
               │                                 cohorts) + ATTACH the CDM READ_ONLY
               └──────── omop-data volume ◀──────┘
                 delphi-100k_5.4.zip                     (downloaded once)
                 delphi-100k_5.4_<duckdb>.duckdb         (built once)
                 delphi-100k.duckdb → link to the above  (fixed path)

opal ──ROCK_HOSTS──▶ rock     (unchanged from iteration 1)
```

One image, two containers: the loader fills the volume and exits, then Rock starts.
The CDM is immutable source data; analysts' cohorts live in each session's memory.

## Goals

- `tilt up` builds the Rock image, loads Delphi-100k once into the `omop-data` volume, then starts Rock.
- Later `tilt up` runs skip the load in seconds (the data is already there).
- Rock reads the CDM read-only; several sessions can read it at once.
- `Rscript deploy/scripts/smoke-test.R` also builds a `cdm` with `CDMConnector::cdmFromCon()` inside Rock and counts `person`.

## Non-goals

- Opal resource and resolver (next step). Whether to use dsOMOP's `omop.dbi.db` or our own small resolver is open: see ADR-0003.
- dsOMOP. Its DuckDB connection opens read-write (`R/resource.R`: `read_only = FALSE`), which locks out other sessions.
- `*DS` functions, CohortConstructor in Rock, HERON `renv.lock` pinning (#17).
- Mongo / Postgres / MariaDB: Opal's data databases only hold imported tables; we import none.

## Decisions

| Topic | Decision | Source |
|---|---|---|
| CDM storage | DuckDB file | team decision (HERON test on Delphi) |
| Loading | Automatic on `tilt up` | user |
| Loader | One-off compose service `delphi-setup` using the Rock image (option C) | user + Claude |
| Download + build | `CDMConnector::eunomiaDir("delphi-100k", "5.4")`: DARWIN's own cache, same storage as omock, version-named file | Claude's call, from research |
| Rock image | `deploy/Dockerfile`: `datashield/rock-base:6.3.5-R4.6.1` + `duckdb` + `CDMConnector` from Rock's dated Posit snapshot | Claude's call |
| Concurrency | In-memory DuckDB + `ATTACH … (READ_ONLY)` per session | proven on GiBleed: 2 parallel sessions OK, read-write locks others out |
| Fixed path | `/data/delphi-100k.duckdb` symlink to the version-named file | Claude's call |
| Rock access | `omop-data:/data:ro` | Claude's call |
| Proof | Smoke test: admin R session in Rock (`opalr::opal.execute`) builds a `cdm` with `cdmFromCon` and counts `person` | Claude's call |

Prior art checked: OHDSI Broadsea bakes a 7 MB demo CDM into a Postgres image (too big for 1.5 GB);
CDMConnector's `eunomiaDir()` caches a version-named DuckDB file (used here);
dsOMOP CI fills Postgres/MySQL service containers; HERON expects the site's own DBI connection.
`duckdb/duckdb-docker` is only the DuckDB CLI (no server), so it can't serve Rock.

## Files

- `deploy/Dockerfile`: the Rock image.
- `deploy/scripts/load-delphi.R`: the loader: `CDMConnector::eunomiaDir()` (its own cache skips download and build) plus a fixed-name link. A run killed mid-build leaves a broken file that `eunomiaDir()` reuses: delete the `omop-data` volume to rebuild.
- `deploy/docker/docker-compose.yml`: `delphi-setup` service, `rock` on the built image, `omop-data` volume.
- `deploy/scripts/smoke-test.R`: builds a `cdm` inside Rock (read-only attach + `cdmFromCon`) and counts `person`.

## What survives what

| Action | `omop-data` (Delphi) | `opal-home` | `rock-home` | session cohorts |
|---|---|---|---|---|
| container stop / crash, `tilt down` → `tilt up`, image rebuild | kept | kept | kept | gone |
| `docker volume rm dsdarwin_omop-data` | rebuilt on next `tilt up` (re-download) | kept | kept | gone |

## Found while building

- Tilt ignores compose `depends_on` (a `dc_resource` is "ready" once its container starts), so Rock started
  0.3 s after the loader. `deploy/Tiltfile` adds `delphi-setup-done`, a `local_resource` that runs
  `docker wait` on the loader; Rock depends on it. Plain `docker compose up` still uses `depends_on`.
  Verified on a fresh `tilt down` → `tilt up`: loader 15:00:18.7–19.8 (exit 0), Rock started 15:00:20.7.
  `resource_deps` only gate the first deploy after Tilt starts: editing the compose file in a running
  session redeploys in Tilt's own order (and may leave `opal` stopped: `tilt trigger opal`).
- First load (build + download + DuckDB build): ~78 s here; later runs skip in under a second.
- `omop-data` holds ~4.1 GB: the 1.57 GB zip plus the 2.58 GB DuckDB file (built with duckdb 2.0).
- Delphi-100k has 99,523 `person` rows.

## Rules

- Rock's duckdb is the writer's duckdb: the loader runs in the same image, so versions match by construction.
- DuckDB reads older files (backward compatible) but not newer ones; a newer duckdb in the image still reads the existing file.
- No Delphi-specific names in package code; Delphi appears only in the loader and the data path.

## Done when

1. Fresh volume: `tilt up` → `delphi-setup` downloads and builds, exits 0; `rock` and `opal` start after it.
2. `Rscript deploy/scripts/smoke-test.R` passes: dsBase methods listed and `person` count > 0 (Delphi-100k: 99,523).
3. `tilt down && tilt up` → `delphi-setup` exits in seconds without downloading; smoke test passes again.

## Next

Opal resource for the CDM, and the same `cdmFromCon` call moved from the admin smoke test into a DataSHIELD `*DS` function; decide dsOMOP vs own resolver.
