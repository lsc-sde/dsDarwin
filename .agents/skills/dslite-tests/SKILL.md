---
name: dslite-tests
description: Writes testthat tests for DataSHIELD client and server functions that run for real against DSLite, an in-process DataSHIELD server with built-in test datasets — no Opal or Armadillo server, no credentials, no mocks of DataSHIELD itself. Use when adding or fixing tests for a DataSHIELD package, setting up DSLite in tests/testthat, or testing disclosure checks.
license: GPL-3.0-only
---

# DSLite tests for DataSHIELD packages

DSLite runs the DataSHIELD server interface inside the R session: client
functions log in, send calls and get real results, from the server
functions of the installed server package. Tests built on it exercise the
real code path end to end.

## First look at what's there

Read `tests/testthat/` before writing anything:

- **A setup already exists** (`setup*.R`, `helper*.R`, or files they
  `source()`): use exactly its connections, data symbols and helper
  functions, under its names. Add no login code — a second login breaks
  the session.
- **Test files named by category**, e.g. `test-smk-ds.mean.R`,
  `test-arg-ds.mean.R` (as in dsBaseClient): put each new test into the
  file of its category (table below), and create the file the same way if
  it doesn't exist.
- Otherwise: one file per R file, `test-<R file name>.R`.

## Setting up DSLite (only when none exists)

`tests/testthat/setup.R` (or `setup-dslite.R` if a `setup.R` with other
content exists — testthat runs every `setup*.R`):

```r
require('DSLite')
require('DSI')
require('<client package>')

logindata <- DSLite::setupCNSIMTest(packages = c("<client package>"))
conns <- DSI::datashield.login(logins = logindata, assign = TRUE)
```

This logs in to three studies with the chosen dataset assigned as `D` on
each. Pass `datasources = conns` (or `conns[1]`, `conns[1:2]`) and refer to
data as `"D"` and `"D$LAB_TSC"`.

The server package must be **installed** wherever the tests run: DSLite
finds server methods through the installed packages' `inst/DATASHIELD`
files. In the client package, list the server package and DSLite in
`Suggests`, so CI installs them.

### Choosing the dataset

| Setup function | Rows/study | Columns | Use when |
|---|---|---|---|
| `setupCNSIMTest` | 2163 | continuous lab values (`LAB_TSC`, `LAB_TRIG`, `LAB_HDL`, `LAB_GLUC_ADJUSTED`), `PM_BMI_CONTINUOUS`, binary `DIS_CVA`, `DIS_DIAB`, `MEDI_LPD` | the default for numeric/tabular functions |
| `setupDASIMTest` | 10000 | like CNSIM, larger | behaviour depends on sample size |
| `setupDATASETTest` | 71 | `CHARACTER`, `LOGICAL`, `NA_VALUES`, `NULL_VALUES`, `INTEGER`, `NON_NEGATIVE_INTEGER`, `POSITIVE_INTEGER`, … | types, missing values, value ranges |
| `setupDISCORDANTTest` | 12 | `A`, `B` | concordance/discordance of paired variables |
| `setupSURVIVALTest` | 2060 | `time.id`, `starttime`, `endtime`, `survtime`, `cens`, `age.60` | survival/time-to-event analysis |

## What to test

| Category | What it checks |
|---|---|
| `arg` | errors and messages for missing, wrongly typed or invalid arguments |
| `smk` | the function runs on the standard data and returns the expected structure and values |
| `disc` | disclosive results are blocked, with the expected error |
| `discctrl` | behaviour under the server's disclosure settings (e.g. `nfilter.tab`) |
| `math` | results agree with the same computation done locally in R |
| `expt` | values match known reference results |

For every new function: at least `arg`, `smk` and — for aggregate functions
— `disc`.

- **Real values, not mocks.** Assert on what the function returns. For
  `math` tests, compute the same quantity locally on the dataset (DSLite's
  datasets are available as R data) and compare with a tolerance.
- **Disclosure tests** request something that must be refused (a subgroup
  smaller than `nfilter.tab`, all levels of an ID-like variable, …) and
  expect the error: `expect_error(ds.foo(...), "...")`.
- **Clean up** objects a test creates on the servers (`ds.rm()` or the
  package's helper), so tests don't depend on each other's order.
- **Don't** test the client's argument checks through the server, or
  vice versa; each check where it lives.

## Utility functions (no connections)

For analyst-side helpers that work on local files: run them in a temporary
directory (`withr::local_tempdir()`), assert on the return value and the
files created, and mock only calls that install packages, reach the network
or open RStudio (`testthat::local_mocked_bindings()`).

## Before finishing

Run the tests (`devtools::test()` or `testthat::test_file()`); a test that
was never run doesn't count. A test that fails because the function is
wrong is a finding to report, not something to adjust the expectation to.
