# Iteration 9: pin the Rock image's DARWIN packages (#17)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Date: 2026-11-23. Builds on [iteration 8](iteration-8-rock-server-packages-plan.md).
ADR candidates: none (image build pins; reversible in one PR, no change to what crosses the client/server boundary).

**Goal:** The Rock image installs exact DARWIN package versions, checked against HERON, and the build fails if it cannot.

**Architecture:** `deploy/Dockerfile` installs the DARWIN packages with one `pak::pak()` call using exact `pkg@version` refs.
pak installs those versions or errors, so the build itself is the version check: no lockfile, no separate check script.
R is pinned by the base image tag; unpinned dependencies resolve from Rock's dated Posit snapshot (`p3m.dev/cran/__linux__/noble/2026-10-28`).

**Tech Stack:** Docker, `datashield/rock-base:6.3.5-R4.6.1`, pak 0.11.1 (already in rock-base).

**Spec:** issue #17, re-scoped on 2026-11-23 (below).

## Why the issue is re-scoped

#17 asked to match HERON's `CharacterisationCode/renv.lock` (R 4.5.2, CohortConstructor 0.6.0, CDMConnector 2.2.0, ...).
Instead we keep the newer versions in the Rock image and pin them. HERON `RunCharacterisation.R` was run on Delphi-100k in the image and compared with a native run on the lockfile (macOS, 2026-11-16), in two variants: `asis` (dates from 2012) and `alldates` (no date filter).

| | HERON lockfile (native) | Rock image, pinned |
|---|---|---|
| R | 4.6 | 4.6.1 |
| CohortConstructor | 0.6.0 | 0.6.3 |
| CDMConnector | 2.2.0 | 2.8.0 |
| omopgenerics | 1.3.4 | 1.4.2 |
| PatientProfiles | 1.4.4 | 1.6.1 |
| CohortCharacteristics | 1.1.0 | 1.1.3 |
| OmopConstructor | 0.1.0 | 0.3.0 |
| OmopSketch | GitHub `852e6f9` (1.0.0.900) | 1.1.1 (latest CRAN) |
| duckdb | 2.0.0 | 2.0.0 |

**With OmopSketch at HERON's commit `852e6f9`:**

- Same row counts (29,743 and 254,536) and the same 24 result sets.
- Every count, percentage, mean and quantile is identical, and the same cells are suppressed.
- Remaining differences:
  - `density_x`/`density_y` plot points.
  - The integer/numeric label on age and observation quantiles; the values are the same.
  - Timestamps.

**With OmopSketch 1.1.1 (chosen; user decision 2026-11-23):**

- The numbers hold. Of the matched values, only one 2014 median age changed (19 → 19.5).
- The output layout changes:
  - Clinical-records and observation-period results gain `type_concept_id` and `is_required` breakdowns.
  - Record trends split into `start_date` and `end_date` series.
  - Some labels are renamed, for example "Type concept id" → "Type concept".
  - Rows: +48 (`asis`) and +1,182 (`alldates`).
- So results from this image are shaped differently from HERON's own runs on `852e6f9`. Anything that compares the two, or loads them into HERON's Shiny app, has to allow for that.

Revised done-when for #17:

- [x] Rock image pins R and the DARWIN packages above; the build fails if a pinned version cannot be installed.
- [x] HERON on Delphi-100k gives the same numbers in the pinned image as natively on the lockfile (above).
- Through Opal: moves to the HERON analysis work (#12), since the `ds.*` functions HERON needs don't exist yet.

## Global Constraints

- Pins, verbatim: `CohortConstructor@0.6.3`, `CDMConnector@2.8.0`, `omopgenerics@1.4.2`, `PatientProfiles@1.6.1`, `CohortCharacteristics@1.1.3`, `OmopConstructor@0.3.0`, `OmopSketch@1.1.1`, `duckdb@2.0.0`.
- Base image stays `datashield/rock-base:6.3.5-R4.6.1`.
- No Delphi-specific code; the image must still serve any OMOP CDM.

## Review Focus

- A pinned version no longer current in the snapshot (after a base-image bump): pak fetches it from the CRAN archive, possibly building from source; it must not install another version.
- A dependency pulling a different version of a pinned package: refs in one `pak::pak()` call resolve together; `install-server-packages.R` installs only *missing* packages, so it can't change them afterwards.
- Delphi loader: `delphi-setup` uses the same image, so duckdb 2.0.0 writes and reads the CDM file; the existing volume keeps working.

---

### Task 1: Pin the DARWIN packages in the Rock image

**Files:**
- Modify: `deploy/Dockerfile` (the package-install `RUN` and its comment)
- Modify: `AGENTS.md` (repo layout line for `deploy/Dockerfile`)

**Interfaces:**
- Produces: image `dsdarwin/rock:dev` with the pinned versions; used unchanged by `deploy/docker/docker-compose.yml` (`rock`, `delphi-setup`).

- [x] **Step 1: Prove the build fails on a wrong pin.** `CohortConstructor@9.9.9`, then
  `docker compose -f deploy/docker/docker-compose.yml build delphi-setup`.
  Result: exit 1, `CohortConstructor: Conflicts with CohortConstructor@9.9.9`.
- [x] **Step 2: Implement.** One `pak::pak(c(<pins>))` call replaces `install.packages(...)` and the `requireNamespace` check.
- [x] **Step 3: Build.** Same command. Result: exit 0; `dsCohortConstructor` and `dsDarwinHelpers` install and load.
- [x] **Step 4: Verify versions** with `packageVersion()` inside `dsdarwin/rock:dev`. Result: exactly the pins, R 4.6.1.
- [x] **Step 5: Re-run the HERON comparison** in the new image on Delphi-100k, `asis` and `alldates`. Result: as above.
- [x] **Step 6: Update `AGENTS.md`** layout line.

Commits: none until the user has reviewed.
