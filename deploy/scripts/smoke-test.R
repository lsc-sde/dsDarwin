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

