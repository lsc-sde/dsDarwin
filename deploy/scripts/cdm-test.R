# This code demonstration of cdm object and aggregated results

library(DSOpal)
url <- Sys.getenv("OPAL_URL", "http://localhost:8880")


# Helper function - Need to register to Rock 
cdmFromConDS <- function() {
    path <- getOption("dsDarwin.cdm.path")
    con <- DBI::dbConnect(duckdb::duckdb())
    DBI::dbExecute(con, paste("ATTACH", DBI::dbQuoteString(con, path), "AS cdm (READ_ONLY)"))
    CDMConnector::cdmFromCon(con, cdmSchema = c(catalog = "cdm", schema = "main"), writeSchema = "main")
}

# Admin - opalr
o <- opalr::opal.login("administrator", "password", url = url)
opalr::dsadmin.set_method(o, "cdmFromConDS", func = cdmFromConDS, type = "assign")
opalr::dsadmin.set_option(o, "dsDarwin.cdm.path", "/data/delphi-100k.duckdb") # Same as profile

if (!opalr::oadmin.user_exists(o, "analyst")) {
  opalr::oadmin.user_add(o, "analyst", password = "Password1@")
}
opalr::dsadmin.perm_add(o,"analyst", type="user",permission = "use")

opalr::dsadmin.profile_enable(o, "default")
opalr::opal.logout(o)


# Analyst perspective
builder <- DSI::newDSLoginBuilder()
builder$append(
    server = "local", url = url, user = "analyst",
    password = "Password1@", driver = "OpalDriver"
)
con <- DSI::datashield.login(builder$build())

DSI::datashield.assign.expr(con, "cdm", quote(cdmFromConDS()))

# Allowed: a published aggregate method. Only the class comes back.
print(DSI::datashield.aggregate(con, quote(classDS("cdm"))))


#Not allowed: a person counts
try(DSI::datashield.aggregate(con, quote(cdm$person)))
DSI::datashield.errors()


DSI::datashield.logout(con)
