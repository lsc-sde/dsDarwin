# Check the if dataSHIELD functions are registred 
# the dsBase methods that Rock serves. Run after `tilt up` shows all green:
# Rscript deploy/scripts/smoke-test.R
library(DSOpal) # registers the OpalDriver class DSI looks up by name
builder <- DSI::newDSLoginBuilder()

builder$append(
  server = "local",
  url = Sys.getenv("OPAL_URL", "http://localhost:8880"),
  user = "administrator",
  password = "password",
  driver = "OpalDriver"
)

conns <- DSI::datashield.login(builder$build())
Sys.sleep(5)
methods <- DSI::datashield.methods(conns, type = "aggregate")

DSI::datashield.logout(conns)
if (!any(methods$package == "dsBase")) {
  stop(
    "Opal is up but lists no dsBase aggregate methods: ",
    "Rock unreachable or default profile empty"
  )
}
print(utils::head(methods[methods$package == "dsBase", c("name", "version")]))

# Check Rock can build a cdm object like a native study does: an admin R
# session inside Rock (not DataSHIELD) attaches the CDM read-only into a
# writable in-memory DuckDB and calls CDMConnector::cdmFromCon(). Only the
# person count comes back; the cdm object stays in Rock.
o <- opalr::opal.login(
  username = "administrator",
  password = "password",
  url = Sys.getenv("OPAL_URL", "http://localhost:8880")
)
persons <- opalr::opal.execute(o, "local({
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbExecute(con, \"ATTACH '/data/delphi-100k.duckdb' AS cdm (READ_ONLY)\")
  cdm <- CDMConnector::cdmFromCon(
    con,
    cdmSchema = c(catalog = 'cdm', schema = 'main'),
    writeSchema = 'main',
    cdmName = 'delphi-100k'
  )
  dplyr::pull(dplyr::tally(cdm$person))
})")
opalr::opal.logout(o)
if (!isTRUE(persons > 0)) stop("Rock cannot build a cdm with person rows")
cat("person rows in the cdm:", persons, "\n")
