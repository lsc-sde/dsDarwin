# CohortConstructor through DataSHIELD, from the analyst's side, on Delphi-100k.
# Every ds.* call builds a cohort inside Rock; only its class comes back.
# Run after `cd deploy && tilt up` and once `Rscript examples/concept-cohort.R`
# (registers cdmFromConDS() and publishes dsCohortConstructor).
# Run: Rscript examples/cohort-walkthrough.R

library(DSOpal)
library(dsCohortConstructorClient)

opal_url <- Sys.getenv("OPAL_URL", "http://localhost:8880")

show_class <- function(conns, symbol) {
  print(DSI::datashield.aggregate(conns, call("classDS", symbol)))
}

show_refusal <- function(conns, expr) {
  try(DSI::datashield.aggregate(conns, expr), silent = TRUE)
  print(DSI::datashield.errors())
}

builder <- DSI::newDSLoginBuilder()
builder$append(
  server = "local",
  url = opal_url,
  user = Sys.getenv("OPAL_ANALYST_USER"),
  password = Sys.getenv("OPAL_ANALYST_PASSWORD"),
  driver = "OpalDriver"
)
conns <- DSI::datashield.login(builder$build())
DSI::datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))

cat("\n== 1. Raw OMOP data: refused ==\n")
show_refusal(conns, quote(cdm$person))

cat("\n== 2. demographicsCohort: everyone in observation ==\n")
ds.demographicsCohort("cdm", "population", sex = "Both", datasources = conns)
show_class(conns, "cdm$population")

cat("\n== 3. demographicsCohort: women by age, 1 year prior observation ==\n")
ds.demographicsCohort(
  cdm = "cdm",
  name = "women_by_age",
  ageRange = list(c(0, 17), c(18, 64), c(65, 150)),
  sex = "Female",
  minPriorObservation = 365,
  datasources = conns
)
show_class(conns, "cdm$women_by_age")

cat("\n== 4. renameCohort: population -> general_population (HERON) ==\n")
ds.renameCohort(
  cdm = "cdm",
  cohort = "population",
  newCohortName = "general_population",
  datasources = conns
)
show_class(conns, "cdm$population")

cat("\n== 5. conceptCohort: chronic kidney disease, from the diagnosis ==\n")
ds.conceptCohort(
  cdm = "cdm",
  conceptSet = list(ckd = 46271022),
  name = "ckd",
  datasources = conns
)
show_class(conns, "cdm$ckd")

cat("\n== 6. The cohort's rows: refused ==\n")
show_refusal(conns, quote(cdm$ckd))

#trimToDateRange(), settings(), cohortCount() and attrition() are
# not wrapped yet; add their steps here when their ds.* pairs land.

DSI::datashield.logout(conns)
