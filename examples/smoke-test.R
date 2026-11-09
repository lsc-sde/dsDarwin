# Check the if dataSHIELD functions are registred 
# the dsBase methods that Rock serves. Run after `tilt up` shows all green:
# Rscript examples/smoke-test.R
library(DSOpal) # registers the OpalDriver class DSI looks up by name
builder <- DSI::newDSLoginBuilder()

builder$append(
  server = "local",
  url = Sys.getenv("OPAL_URL", "http://localhost:8880"),
  user = "administrator",
  password = "password",
  driver = "OpalDriver"
)
# First boot: Opal answers HTTP ~20s before it accepts logins. Retry for 2 min.
Sys.sleep(5)
conns <- tryCatch(DSI::datashield.login(builder$build()),error = function(e) e)

methods <- DSI::datashield.methods(conns, type = "aggregate")

DSI::datashield.logout(conns)
if (!any(methods$package == "dsBase")) {
  stop(
    "Opal is up but lists no dsBase aggregate methods: ",
    "Rock unreachable or default profile empty"
  )
}
print(utils::head(methods[methods$package == "dsBase", c("name", "version")]))
