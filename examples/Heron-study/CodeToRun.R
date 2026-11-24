# HERON-UK Characterisation through DataSHIELD: HERON's
# CharacterisationCode/CodeToRun.R, analyst side.
# Run from the repo root: Rscript examples/Heron-study/CodeToRun.R
# Build order of the ds.* functions still missing:
# spec/iteration-plans/iteration-9-heron-study-plan.md
#
# Needs on each server (Opal admin, admin block of examples/concept-cohort.R):
#   - server packages published: dsCohortConstructor; later dsOmopSketch,
#     dsCohortCharacteristics, dsOmopConstructor
#   - assign method cdmFromConDS + option dsDarwin.cdm.path
#     (later an Opal resource, ADR-0003)
# Server session objects:
#   cdm             cdm_reference: CDM attached read-only, cohorts written to
#                   the in-memory `main` schema
#   cdm$population  cohort_table built by ds.demographicsCohort
#   cdm_op          cdm with a rebuilt observation_period (step 9)
# What comes back: one summarised_result per server and aggregate, bound here
# and exported.

library(DSOpal)
library(dsCohortConstructorClient)
# library(dsOmopSketchClient)            # NOT DEVELOPED [steps 1, 2, 6, 7, 8]
# library(dsCohortCharacteristicsClient) # NOT DEVELOPED [step 5]
# library(dsOmopConstructorClient)       # NOT DEVELOPED [step 9]

studyDir <- file.path("examples", "Heron-study")

# HERON's dbName, con, cdmSchema, writeSchema and prefix are set by each
# server's admin; cdm_name comes back in the results.
url <- Sys.getenv("OPAL_URL", "http://localhost:8880")
builder <- DSI::newDSLoginBuilder()
builder$append(
  server = "local",
  url = url,
  user = Sys.getenv("OPAL_ANALYST_USER"),
  password = Sys.getenv("OPAL_ANALYST_PASSWORD"),
  driver = "OpalDriver"
)
conns <- DSI::datashield.login(builder$build())

DSI::datashield.assign.expr(conns, "cdm", quote(cdmFromConDS()))

# Applied again at export; each server has already suppressed with its own
# threshold (#16).
minCellCount <- 5

# HERON: as.Date(c("2012-01-01", NA)). Delphi-100k has no data after 2011.
dateRange <- as.Date(c(NA, NA))

runCharacterisation <- TRUE
runOmopConstructor <- TRUE

source(file.path(studyDir, "RunCharacterisation.R"))

DSI::datashield.logout(conns)
