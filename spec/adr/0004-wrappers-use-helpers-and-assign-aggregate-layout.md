# ADR-0004: Wrapped functions reuse the dsDarwinHelpers and are filed by assign or aggregate

**Status:** Proposed
**Date:** 2026-11-23

ADR threshold met: expensive to reverse. It sets the shape of every client/server pair in every wrapped DARWIN package, so changing it later means reworking all of them.

## Context

dsDarwin will wrap many DARWIN functions across many packages, each as a client/server pair ([ADR-0002](0002-package-and-function-naming.md)).
Most of the code in a pair is the same every time, whatever the DARWIN function:

- Client: build the DataSHIELD call, turn object names into symbols, find the connections, send the call as assign or aggregate.
- Server: check the `cdm` and the table to write, read the disclosure threshold, hide small counts before anything is returned.

Written out again in every pair, this code would be copied dozens of times. A fix or a tighter disclosure check would then have to be made in every copy, and any copy that was missed would still run the old code.

The first two pairs (`conceptCohort`, `demographicsCohort`) already share this code through `helpers/dsDarwinHelpers`:

- Client (`dsDarwinHelpersClient`): `makeAssignWrapper()`, `makeAggregateWrapper()`, `buildDSCall()`, `AsSymbol()`, `findConnections()`.
- Server (`dsDarwinHelpers`): `checkCohortTarget()`, `nfilterTab()`, `applyDisclosureControl()`.

Whether a function is assign or aggregate decides what can come back to the analyst. Today you only find out from `inst/DATASHIELD` or by reading the function body.
R loads only the files directly in `R/` and ignores subfolders such as `R/assign/`, so assign/aggregate folders inside `R/` are not possible.

## Decision

**We reuse the helpers instead of writing the shared code again in each pair.** A wrapped function contains only what is specific to it: how its arguments map to the server call, and the DARWIN function it runs. The rest comes from `dsDarwinHelpers` / `dsDarwinHelpersClient`.

When a new pair needs shared code that no helper has yet, we add a helper rather than writing it into the pair.

We also group files by assign or aggregate. Because `R/` can't have subfolders, the grouping is a prefix on the file name that matches the file's section in `inst/DATASHIELD`:

| Package | Assign | Aggregate (example) |
|---|---|---|
| Server `R/` | `assign-conceptCohortDS.R` | `aggregate-cohortCountDS.R` |
| Client `R/` | `assign-ds.conceptCohort.R` | `aggregate-ds.cohortCount.R` |
| `tests/testthat/` | `test-assign-conceptCohortDS.R` | `test-aggregate-cohortCountDS.R` |

Function names stay as in ADR-0002; only file names change.

## Consequences

- New wrappers are quicker to write and short to read: the body shows only what differs from other wrappers.
- Shared code is written, tested and fixed in one place, and every pair gets the fix. Disclosure checks can't drift apart between pairs.
- A file listing shows which functions can return results to the analyst (`aggregate-*`), so disclosure review can start there.
- Every wrapped package depends on the helper packages, so one helper change affects all pairs. Helper changes need the same care as changes to functions analysts call.
- Existing `dsCohortConstructor` files and their tests need renaming to `assign-*`. Once this ADR is Accepted, add the rules to [conventions.md](../constraints/conventions.md).
