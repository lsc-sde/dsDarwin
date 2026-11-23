# DSLite server; cdmFromConDS returns GiBleed instead of opening dsDarwin.cdm.path.
dslite.server <- DSLite::newDSLiteServer(
  config = DSLite::defaultDSConfiguration(include = "dsCohortConstructor")
)
dslite.server$assignMethod(
  "cdmFromConDS",
  function() suppressMessages(omock::mockCdmFromDataset("GiBleed", source = "duckdb"))
)
# c and list come from dsBase in Opal's `default` profile.
dslite.server$assignMethod("c", "base::c")
dslite.server$assignMethod("list", "base::list")
assign("dslite.server", dslite.server, envir = globalenv())

builder <- DSI::newDSLoginBuilder()
builder$append(server = "study1", url = "dslite.server", driver = "DSLiteDriver")
conns <- DSI::datashield.login(builder$build())
DSI::datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))
withr::defer(DSI::datashield.logout(conns), teardown_env())

# Test-only look into the DSLite session (never possible through Opal).
serverCdm <- function() {
  dslite.server$getSessionData(dslite.server$getSessionIds()[[1]], "cdm")
}

nativeGibleedCount <- function() {
  cdm <- suppressMessages(omock::mockCdmFromDataset("GiBleed", source = "duckdb"))
  cohort <- suppressMessages(
    CohortConstructor::conceptCohort(cdm, list(gi_bleed = 192671L), name = "gibleed")
  )
  omopgenerics::cohortCount(cohort)
}
