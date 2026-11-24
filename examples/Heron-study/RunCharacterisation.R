# HERON's CharacterisationCode/RunCharacterisation.R, analyst side.
# Sourced by CodeToRun.R.
# Removed: logSql / logSqlExplain (SQL runs on the servers), listSourceTables
# (session tables vanish at logout).

startTime <- Sys.time()

outputFolder <- file.path(studyDir, "Results")
dir.create(outputFolder, showWarnings = FALSE)
source(file.path(studyDir, "scripts", "functions.R"))

logFile <- file.path(outputFolder, paste0(
  "log_dsDarwin_", format(Sys.time(), "%d_%m_%Y_%H_%M_%S"), ".txt"
))
omopgenerics::createLogFile(logFile = logFile)

result <- list()

if (runCharacterisation) {
  omopgenerics::logMessage("Summarising IMD records")
  result[["summaryIMD"]] <- summariseImdRecords(
    cdm = "cdm",
    datasources = conns
  )

  omopTableName <- c(
    "visit_occurrence", "visit_detail", "condition_occurrence",
    "drug_exposure", "procedure_occurrence", "device_exposure",
    "measurement", "observation", "death", "note", "payer_plan_period",
    "drug_era", "dose_era", "condition_era"
  )

  sex <- FALSE
  ageGroup <- NULL
  interval <- "years"

  omopgenerics::logMessage("Starting characterisation")
  result[["characterisation"]] <- databaseCharacteristics(
    cdm = "cdm",
    omopTableName = omopTableName,
    sex = sex,
    ageGroup = ageGroup,
    interval = interval,
    inObservation = TRUE,
    dateRange = dateRange,
    datasources = conns
  )
}

if (runOmopConstructor) {
  observationPeriods <- list(
    first_to_extract = list(
      collapseDays = Inf, persistenceDays = Inf, name = "First to extract"
    ),
    first_to_last = list(
      collapseDays = Inf, persistenceDays = 0, name = "First to last"
    ),
    ongoing = list(
      collapseDays = 1, persistenceDays = 0, name = "Ongoing"
    ),
    collapse_365 = list(
      collapseDays = 365, persistenceDays = 0, name = "Collapse 365"
    ),
    persistence_365 = list(
      collapseDays = 365, persistenceDays = 364, name = "Persistence 365"
    ),
    collapse_730 = list(
      collapseDays = 730, persistenceDays = 0, name = "Collapse 730"
    ),
    persistence_730 = list(
      collapseDays = 730, persistenceDays = 729, name = "Persistence 730"
    )
  )
  for (id in names(observationPeriods)) {
    definition <- observationPeriods[[id]]
    result[[id]] <- summariseCustomObservationPeriod(
      cdm = "cdm",
      collapseDays = definition$collapseDays,
      persistenceDays = definition$persistenceDays,
      dateRange = dateRange,
      name = definition$name,
      datasources = conns
    )
  }
}

result <- Filter(Negate(is.null), result)

dur <- abs(as.numeric(Sys.time() - startTime, units = "secs"))
omopgenerics::logMessage(paste(
  "Study code finished. Code ran in",
  floor(dur / 60), "min and", dur %% 60 %/% 1, "sec"
))

if (length(result) == 0) {
  omopgenerics::logMessage(
    "No results yet: every summarise step is NOT DEVELOPED"
  )
} else {
  result <- omopgenerics::bind(result)
  omopgenerics::logMessage("Exporting results")
  omopgenerics::exportSummarisedResult(
    result,
    minCellCount = minCellCount,
    path = outputFolder,
    fileName = "result_characterisation_dsDarwin_{date}.csv",
    logSqlPath = NULL
  )
}
