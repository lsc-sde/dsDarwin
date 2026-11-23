# HERON-UK Characterisation: analysis for dsDarwin

What the [HERON-UK Characterisation](https://github.com/heron-uk/HERON-UK-Characterisation) study calls, which of its
results dsDarwin has to reproduce, what our [fedn-ds-sandbox](https://github.com/lsc-sde/fedn-ds-sandbox) already wraps,
and what dsDarwin still has to decide. Issue #12; design: [iteration 4](../spec/iteration-plans/iteration-4-heron-analysis-design.md).

## Baseline

HERON (`CharacterisationCode/`, commit `443059d`) runs natively on Delphi-100k (OMOP CDM 5.4, 99,523 persons) with the
pinned DARWIN packages: CDMConnector 2.2.0, omopgenerics 1.3.4, OmopSketch 1.0.0.900, OmopConstructor 0.1.0,
CohortConstructor 0.6.0, CohortCharacteristics 1.1.0, PatientProfiles 1.4.4. Every run finishes without error.

- **As released** (`dateRange = 2012-01-01 →`) the results are almost empty: Delphi's observation periods end on or
  before 2012-01-01 and its clinical records on 2011-12-31, so 10 of 11 clinical tables are empty after the date range.
- **All dates** (`dateRange = c(NA, NA)`, one line changed): 59 s, 3.4 GB peak memory, 254,295 result rows, of which
  8,054 suppressed at `minCellCount = 5`. The reference numbers below come from this run.
- Delphi has no IMD records (`observation_source_concept_id = 35812882`), so the IMD result is all zero.
- `buildObservationPeriod()` takes its end date from `cdm_source.source_release_date` (2026-03-11), not from the data.

## Target results

What a dsDarwin run of HERON must give back. **Match** means: the same result keys (`result_type`, settings, group,
strata, variable, estimate name) and the same values within a numeric tolerance, after both sides are suppressed with
the same threshold. Reference values: Delphi-100k, all dates.

### Tier 1

The rows HERON's report (`Report/Report.qmd`) uses, from each `summarised_result` (`strata_level` is `overall` throughout).

#### summarise_omop_snapshot
```
 group_level      variable_name variable_level      estimate_name estimate_value
     overall            general           <NA>       person_count          99523
     overall            general           <NA> vocabulary_version v5.0 27-AUG-25
     overall                cdm           <NA>            version            5.4
     overall                cdm           <NA>       release_date     2026-03-11
     overall observation_period           <NA>              count          99523
     overall observation_period           <NA>         start_date     1926-02-12
     overall observation_period           <NA>           end_date     2012-01-01
```

#### summarise_person
```
 group_level   variable_name variable_level estimate_name   estimate_value
     overall Number subjects           <NA>         count            99523
     overall             Sex         Female         count            50046
     overall             Sex         Female    percentage 50.2858635692252
     overall             Sex           Male         count            49477
     overall             Sex           Male    percentage 49.7141364307748
     overall             Sex           None         count                0
     overall             Sex           None    percentage                0
     overall   Year of birth           <NA>           min             1926
     overall   Year of birth           <NA>        median             1994
     overall   Year of birth           <NA>           max             2011
```

#### summarise_observation_period
```
 group_level      variable_name variable_level estimate_name estimate_value
         all Records per person           <NA>          mean              1
         all Records per person           <NA>        median              1
         all   Duration in days           <NA>          mean 4034.516192237
         all   Duration in days           <NA>        median           2492
         all     Number records           <NA>         count          99523
         all    Number subjects           <NA>         count          99523
```

#### summarise_clinical_records
```
           omop_table  records subjects in_observation_pct standard_concept_pct
     visit_occurrence  1929158    99414             100.00               100.00
 condition_occurrence    39306    22950             100.00               100.00
        drug_exposure   962858    93598              99.43               100.00
 procedure_occurrence   914848    99419             100.00               100.00
          measurement 13713259    99419             100.00               100.00
          observation  1370251    99417             100.00               100.00
             drug_era   237460    38306              95.36               100.00
             dose_era    78803    18775              94.89               100.00
        condition_era    39306    22950             100.00               100.00
                death     2809     2809             100.00                 <NA>
                 note  1499925    99414             100.00                 <NA>
```

Missing data (`Column name`, `na_percentage`): no missing values in any required column, as in HERON's report
("No missings observed in compulsory columns"). 80 optional columns have missing values, many 100 % empty.

#### summarise_trend (records per table, 2011)
```
          group_level     variable_name variable_level estimate_name estimate_value
     visit_occurrence Number of records           <NA>         count         272248
     visit_occurrence Number of records           <NA>    percentage          14.11
        drug_exposure Number of records           <NA>         count         117710
        drug_exposure Number of records           <NA>    percentage          12.23
 procedure_occurrence Number of records           <NA>         count         112199
 procedure_occurrence Number of records           <NA>    percentage          12.26
          measurement Number of records           <NA>         count        1766301
          measurement Number of records           <NA>    percentage          12.88
          observation Number of records           <NA>         count         198304
          observation Number of records           <NA>    percentage          14.47
                death Number of records           <NA>         count            461
                death Number of records           <NA>    percentage          16.41
                 note Number of records           <NA>         count         208496
                 note Number of records           <NA>    percentage          13.90
             drug_era Number of records           <NA>         count          30751
             drug_era Number of records           <NA>    percentage          12.95
             dose_era Number of records           <NA>         count          10990
             dose_era Number of records           <NA>    percentage          13.95
```

#### summarise_characteristics
```
        group_level     variable_name variable_level estimate_name   estimate_value
 general_population    Number records           <NA>         count            99523
 general_population   Number subjects           <NA>         count            99523
 general_population               Age           <NA>        median                6
 general_population               Sex         Female         count            50046
 general_population               Sex         Female    percentage 50.2858635692252
 general_population               Sex           Male         count            49477
 general_population               Sex           Male    percentage 49.7141364307748
 general_population Prior observation           <NA>        median                0
```

### Tier 2

IMD is all zero on Delphi: it needs a CDM that has IMD to test.

#### summarise_observation_period (rebuilt, OmopConstructor)
```
 name_observation_period    variable_name estimate_name estimate_value
        First to extract Duration in days        median           7619
        First to extract   Number records         count          99427
        First to extract  Number subjects         count          99427
           First to last Duration in days        median           2199
           First to last   Number records         count          99427
           First to last  Number subjects         count          99427
                 Ongoing Duration in days        median              1
                 Ongoing   Number records         count        1551172
                 Ongoing  Number subjects         count          99427
            Collapse 365 Duration in days        median              8
            Collapse 365   Number records         count         360852
            Collapse 365  Number subjects         count          99427
         Persistence 365 Duration in days        median            372
         Persistence 365   Number records         count         360852
         Persistence 365  Number subjects         count          99427
            Collapse 730 Duration in days        median           1734
            Collapse 730   Number records         count         136710
            Collapse 730  Number subjects         count          99427
         Persistence 730 Duration in days        median           2452
         Persistence 730   Number records         count         136710
         Persistence 730  Number subjects         count          99427
```

#### summarise_imd
```
 group_level                 variable_name variable_level estimate_name estimate_value
     overall            Number IMD records           <NA>         count              0
     overall Number IMD records per person           <NA>         count              0
     overall Number IMD records per person           <NA>          mean              0
     overall         Most recent IMD value           <NA>         count          99523
```

`summarise_log_file` (step timings) is not a target.

## HERON vs fedn

Every call HERON makes, against [fedn-ds-sandbox](https://github.com/lsc-sde/fedn-ds-sandbox): a DSLite proof of
concept with 21 server functions for 5 DARWIN packages, loaded with `source()` and never run on Opal or Rock.

Not in the table: packages the DARWIN functions call internally (PatientProfiles under OmopSketch and OmopConstructor,
CohortConstructor under OmopSketch). They are never wrapped: they run only inside server functions and come in as
dependencies, installed in the Rock image at HERON's pinned versions.

| HERON call | Package | In fedn | dsDarwin | Note |
|---|---|---|---|---|
| `cdmFromCon` | CDMConnector | inside `getProjectCDM` | **done differently** | dsDarwin's `cdmFromConDS` (iteration 3): CDM attached read-only, writable in-memory schema per session |
| `demographicsCohort` | CohortConstructor | `demographicsCohortDS` | **adapt** | broken: the client always sends `dsAssignSymbol` (`wrapperHelpers.R:102`), the server function has no such argument (`cohortConstructorDS.R:88`) |
| `trimToDateRange` | CohortConstructor | – | **new** | `requireInDateRangeDS` is a different function (drops records instead of trimming) |
| `summariseCharacteristics` | CohortCharacteristics | `summariseCharacteristicsDS` | **adapt** | threshold comes from the client (see below) |
| `summariseOmopSnapshot` | OmopSketch | – | **new** | |
| `summarisePerson` | OmopSketch | – | **new** | |
| `summariseClinicalRecords` | OmopSketch | – | **new** | `conceptSummary` returns per-concept counts: check suppression |
| `summariseObservationPeriod` | OmopSketch | – | **new** | |
| `summariseTrend` | OmopSketch | – | **new** | yearly counts: many small cells |
| `buildObservationPeriod` | OmopConstructor | – | **new** | assign: replaces `observation_period` in the session's cdm |
| IMD summary (study code) | dplyr | – | **new** | must run server-side; returns a `summarised_result`; concept ID (`35812882` in HERON) passed as an argument, not hardcoded |
| `newCohortTable`, `settings`, `newSummarisedResult`, `bind` | omopgenerics | used internally | **internal** | server-side plumbing, not wrapped |
| `isTableEmpty`, `listSourceTables`, `dropSourceTable` | omopgenerics | – | **internal** | |
| `createLogFile`, `logMessage`, `exportSummarisedResult` | omopgenerics | – | **client side** | the client logs, binds and exports what aggregates return |
| `addSexQuery` | PatientProfiles | `addSexDS` (wraps `addSex`) | **not needed** | unreached with HERON's settings |

Of HERON's own calls, 2 exist in fedn, both need fixes; 9 are new. fedn functions HERON does not use: `conceptCohort`,
`measurementCohort`, `requireDemographics`, `requireInDateRange`, the other four CohortCharacteristics summaries, all of
IncidencePrevalence, PhenotypeR, and PatientProfiles except `addSex`.

## Patterns from fedn

**Adapt:**
- One client `ds.*` per server `*DS`, assign vs aggregate split, aggregate returns a `summarised_result`.
- Re-attaching a cohort table with `newCohortTable(table, cohortSetRef, cohortAttritionRef, .softValidation = TRUE)`.
- Writing the new table back into the session's cdm after each assign.
- Running the same pipeline natively as the baseline to compare against.

**Avoid:**
- **Arguments pasted into R code** (`buildDSCall`, `wrapperHelpers.R:36`): strings unescaped, lists `deparse()`d.
  Unsafe, and Opal's parser rejects nested calls.
- **Threshold set by the client**: every aggregate takes `minCellCount` (default 5) from the analyst, who can pass 0.
- **Writing into the CDM**: read-write DuckDB with `writeSchema` = CDM schema; the connection is never closed.
- **Lookups the client steers**: `resolveServerObject` walks `sys.frame()` and can return any named object, or an
  unrelated cohort when the name doesn't match.
- **Raw error messages to the client** (`phenotypeRDS.R`), and state changes inside aggregate calls.
- **String comparison of results** (`run_validation_comparison.R`): exact `==` on `estimate_value`, native side
  unsuppressed, no group/strata keys.

## Still to decide

**writeSchema.** HERON writes `population` (`demographicsCohort()`) and a rebuilt `observation_period` seven times (`buildObservationPeriod()`). dsDarwin
already gives each session a writable in-memory schema with the CDM attached read-only (iteration 3), so these stay in
the session. Open: `buildObservationPeriod()` replaces `cdm$observation_period`; the original must stay available
for the next definition and for Tier 1.

**Disclosure control.** HERON suppresses once, at export, with `minCellCount = 5`. In dsDarwin every aggregate has to
suppress before it returns, with a threshold the server sets
([disclosure-control.md](../spec/constraints/disclosure-control.md)). Which rule applies, omopgenerics `minCellCount`
or DataSHIELD `nfilter.tab`, is #16; dsBase's default `nfilter.tab` is 3, HERON uses 5. Points to cover:
- `summariseTrend` and `summariseClinicalRecords(conceptSummary = TRUE)` produce many small cells; check that
  `suppress()` also hides the percentage linked to a suppressed count.
- Quantiles, min/max and density estimates (`density_x`, `density_y`) describe individuals at the edges: check
  whether `suppress()` covers them or they need their own rule.
- The IMD step `collect()`s row-level observations: it must run inside a server function and return only the summary.
- Error messages must not carry data values.

**Arguments through Opal.** HERON passes `dateRange` (dates), `collapseDays`/`persistenceDays` (numbers, `Inf`), table
name vectors, `ageGroup` lists. Opal's parser accepts simple values only, so vectors and lists need an encoding the
server validates.

**Wrap granularity.** One aggregate per DARWIN `summarise*` function (conventions, ADR-0002) keeps functions small and
reusable, but HERON becomes ~20 round trips. A single HERON-level aggregate would be one call but study-specific.

**Packages.** By the naming conventions HERON needs four server/client pairs: dsCohortConstructor,
dsCohortCharacteristics, dsOmopSketch, dsOmopConstructor; all of them and PatientProfiles installed in the Rock image
at the pinned versions.

**Comparing results.** Suppress the native result with the same threshold, join on all result keys including
settings, compare numbers within a tolerance, and report rows only one side has.

**Test data.** Delphi has no data after 2011 and no IMD: tests use `dateRange = c(NA, NA)`, and Tier 2 IMD needs
another CDM.
