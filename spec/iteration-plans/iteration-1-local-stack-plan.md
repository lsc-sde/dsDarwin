# Iteration 1: local Opal stack (obiba docker compose, wrapped in Tilt)

Issue: #14 (part of epic #11). Date: 2026-11-09.
ADR candidate: [ADR-0003](../adr/0003-cdm-through-opal-resource.md) (Proposed) — how the OMOP CDM reaches Rock; applies from iteration 2.

## Why

Before any `*DS` function can be wrapped we need a place to run it.
This iteration starts Opal and a Rock R server locally, the way the obiba docs install them, driven by Tilt.
No OMOP data yet: Delphi-100k is iteration 2.

## Architecture

```
analyst R session (ds.* + DSI/DSOpal)            ← client side
      │ HTTP :8880
      ▼
   opal   gatekeeper: login, permissions, allowed DataSHIELD methods.
      │   Its own config is H2 under /srv (Opal 6), no database server needed.
      │ ROCK_HOSTS=rock:8085
      ▼
   rock   R server: runs *DS functions, opens DB connections.
      │
      ▼   (iteration 2) Opal resource → DBI → CDMConnector::cdmFromCon
   omop-postgres   cdm + results schemas
```

The data never passes through Opal: Opal only knows where it is (the resource) and who may use it.

## Goals

- `cd deploy && tilt up` starts `opal` and `rock` from `deploy/docker/docker-compose.yml`.
- A DataSHIELD call reaches Rock: `Rscript examples/smoke-test.R` lists the dsBase aggregate methods.
- Opal settings and Rock's installed R packages survive `tilt down` / `tilt up` (named volumes).

## Non-goals

- Kubernetes (`deploy/k8s/` stays a placeholder).
- Mongo, MySQL, MariaDB, Postgres *data databases*: they hold tables imported into Opal, and we never import tables.
- Monitoring (`grafana/otel-lgtm`).
- A custom Rock image, the OMOP database, the Delphi loader, Opal resources (iteration 2).

## Decisions

| Topic | Decision | Source |
|---|---|---|
| Install method | obiba docs "standalone" docker compose | user |
| Containers | `opal`, `rock` only | user |
| Dev loop | Tiltfile wrapping the compose file (`docker_compose`) | user |
| Rock image | `datashield/rock-base` instead of the docs' `obiba/rock`: ships dsBase | Claude's call |
| Image tags | pinned: `obiba/opal:6.1.3`, `datashield/rock-base:6.3.5-R4.6.1` | Claude's call |
| Port | `8880:8080`, as in the docs | Claude's call |
| Password | obiba docs default `password`, dev only, said so in the compose header | Claude's call |
| Volumes | `opal-home:/srv`, `rock-home:/srv` | obiba docs |

## Files

- `deploy/docker/docker-compose.yml`: the stack.
- `deploy/Tiltfile`: `docker_compose(...)` + a link to Opal.
- `examples/smoke-test.R`: the end-to-end check (retries login: Opal needs ~30s on a first boot).
- `AGENTS.md`: repo layout updated.

## Done when

1. `cd deploy && tilt up` → `opal` and `rock` green in the Tilt UI (Opal takes 1–2 min).
2. `Rscript examples/smoke-test.R` exits 0 and prints dsBase aggregate methods.
3. `tilt down && tilt up`, smoke test again → still passes; `docker volume ls` still shows both volumes.

## Next: iteration 2 — bring Delphi-100k

- Add an `omop-postgres` service: own database `omop`, schemas `cdm` + `results`, own volume.
- One-off loader: `omock::mockCdmFromDataset("delphi-100k_5.4")` → `omopgenerics::insertCdmTo()` into Postgres; skipped when data already exists. omock only ships a zip and rebuilds a temp DuckDB per call, so the data must be materialised once.
- Register an Opal resource for it (ADR-0003); proof: a server-side call returns the `person` count (#14 "done when").
- Open questions: Postgres vs DuckDB file; where the loader runs (container or host R); how `resourcer`, `RPostgres`, `CDMConnector` get into Rock.
