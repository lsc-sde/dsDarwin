# End to end on Delphi-100k: build a cohort in Rock; only its class comes back.
# Run after `cd deploy && tilt up` with the client packages installed. Safe to rerun.

library(DSOpal)
library(dsCohortConstructorClient)
url <- Sys.getenv("OPAL_URL", "http://localhost:8880")

# CDM attached read-only; cohorts go to the in-memory `main`.
cdmFromConDS <- function() {
  path <- getOption("dsDarwin.cdm.path")
  con <- DBI::dbConnect(duckdb::duckdb())
  DBI::dbExecute(con, paste("ATTACH", DBI::dbQuoteString(con, path), "AS cdm (READ_ONLY)"))
  CDMConnector::cdmFromCon(con, cdmSchema = c(catalog = "cdm", schema = "main"), writeSchema = "main")
}

# Admin - opalr
o <- opalr::opal.login("administrator", "password", url = url)
opalr::dsadmin.set_method(o, "cdmFromConDS", func = cdmFromConDS, type = "assign")
opalr::dsadmin.set_option(o, "dsDarwin.cdm.path", "/data/delphi-100k.duckdb")

# Rock can answer 404 for a moment after start: retry.
for (attempt in 1:5) {
  published <- tryCatch({
    opalr::dsadmin.publish_package(o, "dsCohortConstructor")
    TRUE
  }, error = function(e) {
    message("publish attempt ", attempt, " failed: ", conditionMessage(e))
    FALSE
  })
  if (published) break
  Sys.sleep(2)
}
stopifnot(published)

if (!opalr::oadmin.user_exists(o, "analyst")) {
  opalr::oadmin.user_add(o, "analyst", password = "Password1@")
}
opalr::dsadmin.perm_add(o, "analyst", type = "user", permission = "use")
opalr::dsadmin.profile_enable(o, "default")
opalr::opal.logout(o)


# Analyst perspective
builder <- DSI::newDSLoginBuilder()
builder$append(
  server = "local", url = url, user = "analyst",
  password = "Password1@", driver = "OpalDriver"
)
conns <- DSI::datashield.login(builder$build())

DSI::datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))

# Chronic kidney disease (46271022), Delphi only.
ds.conceptCohort("cdm", list(ckd = 46271022), "ckd" , datasources = conns)

# Allowed: only the class comes back.
print(DSI::datashield.aggregate(conns, quote(classDS("cdm$ckd"))))

ds.demographicsCohort("cdm", "population", datasources = conns)
print(DSI::datashield.aggregate(conns, quote(classDS("cdm$population"))))

ds.demographicsCohort("cdm", "by_age", ageRange = list(c(0, 17), c(18, 64), c(65, 150)), datasources = conns)
print(DSI::datashield.aggregate(conns, quote(classDS("cdm$by_age"))))

# Not allowed: the cohort's rows.
try(DSI::datashield.aggregate(conns, quote(cdm$ckd)), silent = TRUE)
cat("Direct access to cdm$ckd refused (expected):\n")
print(DSI::datashield.errors())

DSI::datashield.logout(conns)
