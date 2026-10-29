---
name: client-server-pair
description: Writes or reviews a DataSHIELD function pair — a client function (ds.*) that builds and sends a call, and the server function (*DS) that computes on the data behind the firewall, with disclosure control. Use when adding a new DataSHIELD function, changing what a client or server function does, or checking that a server function can't return disclosive results.
license: GPL-3.0-only
---

# DataSHIELD client/server pair

DataSHIELD analyses data that never leaves the studies: the analyst calls a
**client** function in R; it sends a call to every connected study's
**server**, where a server function computes on the real data and returns
only non-disclosive results (aggregate) or stores a new object on the
server (assign). Both halves usually live in two packages, e.g.
`dsBaseClient` (client) and `dsBase` (server).

Before writing anything, read two or three existing pairs in the same
packages and follow their conventions — argument names, checks, messages,
file layout. They take precedence over this skill where they differ.

## Decide: aggregate or assign

| | Aggregate | Assign |
|---|---|---|
| Purpose | return a result to the analyst | create or change an object on the server |
| Client sends with | `DSI::datashield.aggregate(datasources, call)` | `DSI::datashield.assign(datasources, newobj, call)` |
| Server returns | a small, non-disclosive R object | the new object (stays on the server) |
| Disclosure risk | high: everything returned leaves the server | lower, but the object can later be aggregated |

A typical assign function is followed by a check that the object exists
on every study (e.g. `ds.exists()` or the package's own helper).

## The client function (`ds.<name>`)

1. **Signature:** the data arguments first; for assign functions the
   name of the new server object (`newobj` or the package's convention);
   `datasources = NULL` last.
2. **Connections:** if `datasources` is `NULL`, take the default ones
   (`DSI::datashield.connections_find()`), then check that it is a list of
   `DSConnection` objects — copy the package's existing check and error
   message.
3. **Argument checks on the client:** types, allowed values, and that the
   server objects named exist (the package's `isDefined()`-style helper),
   with clear errors. Never check data *values* on the client — it can't
   see them.
4. **Build the call** to the server function. Pass server object names as
   symbols (`as.symbol(x)`), so the server evaluates them in its
   environment; pass plain values (numbers, short strings, flags) as
   values. Follow how the package encodes strings with special characters.
5. **Send it** with `datashield.aggregate()` or `datashield.assign()`.
6. **Return** what the analyst needs: aggregate results per study, often
   combined (pooled) on the client; for assign functions usually nothing
   or a status.

Client functions compute nothing on individual data. Pooling across
studies (e.g. combining means weighted by counts) happens on the client,
from what the servers returned.

## The server function (`<name>DS`)

1. **Arguments** arrive as evaluated R objects (for symbols) or values.
   Validate them again: the server must never trust the client.
2. **Compute** with base R, `stats` or the tidyverse, on the real data.
3. **Disclosure control** before returning anything (see below).
4. **Return** for aggregate: only the non-disclosive summary; for assign:
   the new object.

### Registering the method

A server function only runs if the server package declares it. In the
server package, `inst/DATASHIELD` lists the methods (DCF format):

```
AggregateMethods:
  meanDS
AssignMethods:
  asNumericDS
```

Disclosure settings the package defines are declared there too
(`Options:`), following the existing entries. DSLite and Opal/Armadillo
read this file from the installed server package.

## Disclosure control

Everything an aggregate function returns leaves the study. Check, in the
server function, before returning:

- **Small counts:** any count, cell or subgroup below the threshold
  (`nfilter.tab`, `nfilter.subset` — read from the server's disclosure
  settings, never hard-coded) must not be returned; stop with an error
  that says why, without revealing the count.
- **Individual values:** no raw values, no minimum/maximum of a variable,
  no lists of unique values or levels beyond the allowed number
  (`nfilter.levels.max`, `nfilter.levels.density`).
- **Model and dimension checks:** e.g. for regressions, parameters relative
  to observations (`nfilter.glm`); strings limited in length
  (`nfilter.string`, `nfilter.stringShort`).
- **Differencing:** two allowed requests whose difference reveals an
  individual (e.g. a subset with and without one person). Subsetting
  functions must enforce minimum subset sizes for that reason.
- **Noise:** some results are only returned with noise added
  (`nfilter.noise`), following the package's existing approach.

Use the thresholds the package already reads (in dsBase:
`listDisclosureSettingsDS()`), never constants. When unsure whether a
result is disclosive, treat it as disclosive and ask.

## Before finishing

- Client and server argument names match in meaning and order.
- The server function is registered in `inst/DATASHIELD`.
- Disclosure checks are in the **server** function, with tests that the
  disclosive case is blocked (see the `dslite-tests` skill).
- Both functions are documented (see the `roxygen-docs` skill); the client
  docs name the server function it calls.
- For a function that doesn't exist yet in any DataSHIELD package, write a
  design note first (see the `design-note` skill).