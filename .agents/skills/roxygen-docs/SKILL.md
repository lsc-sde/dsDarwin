---
name: roxygen-docs
description: Writes or reviews roxygen2 documentation for functions of DataSHIELD packages — client (ds.*), server (*DS) and analyst-side utility functions — so it says what really happens on the client and on the server, names the server function called, and has a runnable multi-study example. Use when documenting a DataSHIELD function, reviewing its roxygen block, or fixing outdated examples.
license: GPL-3.0-only
---

# Roxygen documentation for DataSHIELD packages

Documentation describes what the code does — read the function before
writing. Never document behaviour the code doesn't have, and never invent a
server function, argument or default.

## Every exported function

Parts in this order: title, description, `@details`, `@param`,
`@return`, other tags, `@author`, `@import`/`@importFrom`, `@examples`,
`@export`.

| Field | Guidance |
|---|---|
| Title | max 10 words, a plain phrase naming what the function does |
| Description | max 2 lines expanding on the title |
| `@details` | up to 4 lines; see the role below |
| `@param` | one line per parameter: expected type and purpose |
| `@return` | 1–2 sentences: type and shape of the value, including disclosure-control behaviour relevant to the caller |
| `@examples` | runnable; see below |

Internal functions: title and `@param`/`@return`; description, details and
examples only where the purpose isn't obvious.

## By role

**Client function** — it builds and sends a call, it doesn't compute:

- `@param`: say when a parameter names an object **on the server** (a
  table or variable name), not a local R value.
- `@return`: what actually comes back in R (results per study, a pooled
  result, a status) — not what the server computes and keeps.
- `@details`: what server call it constructs. If the code names the
  server function, write `Server function called: \code{meanDS}` (in code
  font). Only when the name is identifiable from the code — some client
  packages are standalone wrappers with none.

**Server function** — it computes on the real data:

- `@param`: real, resolved R objects at this point.
- `@return`: the computed result, its type and shape.
- `@details`: the base/stats/tidyverse functions it builds on, and the
  disclosure checks it applies (with the setting names, e.g. `nfilter.tab`).

**Utility function** (analyst side, neither client wrapper nor server
code — project setup, mock data, package management):

- `@param`: a `datasources` argument or server object name refers to
  DataSHIELD connections/objects; everything else is a local value.
- `@return`: the value, and the files or folders created or changed.
- `@details`: side effects on the analyst's machine. Never write "Server
  function called".
- `@examples`: write only into `tempdir()`; don't open RStudio projects
  or sessions.

## Examples for functions that use connections

DataSHIELD is used across several studies at once, so examples log in to
three. Use the public Opal demo server (its published demo credentials):

```r
\dontrun{
require('DSI')
require('DSOpal')
require('dsBaseClient')

builder <- DSI::newDSLoginBuilder()
builder$append(server = "study1", url = "https://opal-demo.obiba.org/",
               user = "dsuser", password = "P@ssw0rd",
               table = "CNSIM.CNSIM1", driver = "OpalDriver")
builder$append(server = "study2", url = "https://opal-demo.obiba.org/",
               user = "dsuser", password = "P@ssw0rd",
               table = "CNSIM.CNSIM2", driver = "OpalDriver")
builder$append(server = "study3", url = "https://opal-demo.obiba.org/",
               user = "dsuser", password = "P@ssw0rd",
               table = "CNSIM.CNSIM3", driver = "OpalDriver")
logindata <- builder$build()
connections <- DSI::datashield.login(logins = logindata, assign = TRUE, symbol = "D")

# the function, on the assigned data D, e.g.
ds.mean(x = "D$LAB_TSC", datasources = connections)

DSI::datashield.logout(connections)
}
```

Replace the package line with the documented package, and the call with
the function at hand on CNSIM columns (`LAB_TSC`, `LAB_TRIG`, `LAB_HDL`,
`PM_BMI_CONTINUOUS`, `DIS_DIAB`, …). Treat an existing example that logs
in to a single server, or to another server or VM, as outdated.
`\dontrun{}` because it needs the network.

## Before finishing

Run `devtools::document()` and check the generated `.Rd` and that
`R CMD check` has no documentation warnings (mismatched `@param` names,
missing arguments).
