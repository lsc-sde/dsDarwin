# HERON's CharacterisationCode/scripts/functions.R as client-side
# compositions of ds.* calls. Each ds.* aggregate returns one
# summarised_result per server; bindServers() makes it one.
# `NOT DEVELOPED [step N]`: the intended call, commented out until its pair
# exists. Order and blockers:
# spec/iteration-plans/iteration-9-heron-study-plan.md

bindServers <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  omopgenerics::bind(unname(x))
}

addObservationPeriodName <- function(x, name) {
  if (is.null(x)) {
    return(NULL)
  }
  set <- omopgenerics::settings(x = x) |>
    dplyr::mutate(name_observation_period = .env$name)
  omopgenerics::newSummarisedResult(x = x, settings = set)
}

# HERON's summariseImdRecords() collect()s observation rows: that code moves
# inside the server function, only the summarised_result comes back.
summariseImdRecords <- function(cdm, datasources) {
  # NOT DEVELOPED [step 10] ds.summariseImdRecords -> summariseImdRecordsDS
  #   (package open, aggregate). Blocked on: package home (ADR candidate);
  #   a CDM with IMD records to test (Delphi has none).
  # bindServers(ds.summariseImdRecords(
  #   cdm = cdm,
  #   conceptId = 35812882,
  #   datasources = datasources
  # ))
  NULL
}

summariseCustomObservationPeriod <- function(cdm,
                                             collapseDays,
                                             persistenceDays,
                                             dateRange,
                                             name,
                                             datasources) {
  omopgenerics::logMessage(paste0("Building observation period ", name))
  # NOT DEVELOPED [step 9] ds.buildObservationPeriod -> buildObservationPeriodDS
  #   (dsOmopConstructor, assign). Stored as `cdm_op` so `cdm` keeps the
  #   original observation_period. Blocked on: Inf through Opal.
  # ds.buildObservationPeriod(
  #   cdm = cdm,
  #   newobj = "cdm_op",
  #   collapseDays = collapseDays,
  #   persistenceDays = persistenceDays,
  #   datasources = datasources
  # )
  res1 <- NULL
  res2 <- NULL

  omopgenerics::logMessage(paste0(
    "Summarise observation period table: ", name
  ))
  # NOT DEVELOPED [step 6] ds.summariseObservationPeriod ->
  #   summariseObservationPeriodDS (dsOmopSketch, aggregate).
  #   Blocked on: suppression rule (#16); dates go as ISO strings (step 4).
  # res1 <- bindServers(ds.summariseObservationPeriod(
  #   cdm = "cdm_op",
  #   byOrdinal = TRUE,
  #   sex = FALSE,
  #   ageGroup = NULL,
  #   dateRange = dateRange,
  #   quality = FALSE,
  #   missingData = FALSE,
  #   datasources = datasources
  # ))

  omopgenerics::logMessage(paste0(
    "Summarise trends of observation period: ", name
  ))
  # NOT DEVELOPED [step 8] ds.summariseTrend -> summariseTrendDS
  #   (dsOmopSketch, aggregate). Blocked on: suppression rule (#16),
  #   character vectors through Opal.
  # res2 <- bindServers(ds.summariseTrend(
  #   cdm = "cdm_op",
  #   ageGroup = NULL,
  #   sex = FALSE,
  #   episode = "observation_period",
  #   interval = "years",
  #   output = c("record", "person", "person-days", "age"),
  #   dateRange = dateRange,
  #   datasources = datasources
  # ))

  result <- Filter(Negate(is.null), list(
    addObservationPeriodName(res1, name),
    addObservationPeriodName(res2, name)
  ))
  if (length(result) == 0) {
    return(NULL)
  }
  omopgenerics::bind(result)
}

# Not ported: HERON's isTableEmpty() loop (steps 7 and 8 drop empty tables on
# the server), dropSourceTable() (session tables vanish at logout),
# PatientProfiles::addSexQuery() (unreached with sex = FALSE).
databaseCharacteristics <- function(cdm,
                                    omopTableName,
                                    sex,
                                    ageGroup,
                                    interval,
                                    inObservation,
                                    dateRange,
                                    datasources) {
  if (!is.null(ageGroup)) {
    # HERON binds a general and an age-group population cohort on the
    # server: no pair is planned for that bind yet.
    cli::cli_abort(c(
      "{.arg ageGroup} is not supported yet.",
      i = "HERON's released run uses {.code ageGroup = NULL}."
    ))
  }

  startTime <- Sys.time()
  result <- list()

  cli::cli_inform(paste(cli::symbol$arrow_right, "Getting cdm snapshot"))
  # NOT DEVELOPED [step 1] ds.summariseOmopSnapshot -> summariseOmopSnapshotDS
  #   (dsOmopSketch, aggregate). First aggregate.
  #   Blocked on: suppression rule (#16).
  # result$snapshot <- bindServers(ds.summariseOmopSnapshot(
  #   cdm = cdm,
  #   datasources = datasources
  # ))

  cli::cli_inform(paste(
    cli::symbol$arrow_right, "Getting population characteristics"
  ))
  sexCohort <- if (sex) "Both"
  ds.demographicsCohort(
    cdm = cdm,
    name = "population",
    sex = sexCohort,
    datasources = datasources
  )

  # [step 3] replaces HERON's settings() + newCohortTable(cohortSetRef = set).
  ds.renameCohort(
    cdm = cdm,
    cohort = "population",
    newCohortName = "general_population",
    datasources = datasources
  )

  # [step 4] Dates cross Opal as "YYYY-MM-DD" strings.
  ds.trimToDateRange(
    cdm = cdm,
    cohort = "population",
    dateRange = dateRange,
    datasources = datasources
  )

  # NOT DEVELOPED [step 5] ds.summariseCharacteristics ->
  #   summariseCharacteristicsDS (dsCohortCharacteristics, aggregate).
  #   Blocked on: nested list through Opal; suppression of quantiles,
  #   min/max and density estimates (#16).
  # result$populationCharacteristics <- bindServers(
  #   ds.summariseCharacteristics(
  #     cohort = paste0(cdm, "$population"),
  #     estimates = list(
  #       date = c("min", "q25", "median", "q75", "max"),
  #       numeric = c(
  #         "min", "q25", "median", "q75", "max", "mean", "sd", "density"
  #       ),
  #       categorical = c("count", "percentage"),
  #       binary = c("count", "percentage")
  #     ),
  #     datasources = datasources
  #   )
  # )

  cli::cli_inform(paste(cli::symbol$arrow_right, "Summarising person table"))
  # NOT DEVELOPED [step 2] ds.summarisePerson -> summarisePersonDS
  #   (dsOmopSketch, aggregate). Blocked on: suppression rule (#16).
  # result$person <- bindServers(ds.summarisePerson(
  #   cdm = cdm,
  #   datasources = datasources
  # ))

  cli::cli_inform(paste(
    cli::symbol$arrow_right, "Summarising clinical records"
  ))
  # NOT DEVELOPED [step 7] ds.summariseClinicalRecords ->
  #   summariseClinicalRecordsDS (dsOmopSketch, aggregate). Server drops
  #   empty tables. Blocked on: character vectors through Opal;
  #   conceptSummary small cells.
  # result$clinicalRecords <- bindServers(ds.summariseClinicalRecords(
  #   cdm = cdm,
  #   omopTableName = omopTableName,
  #   recordsPerPerson = c("median", "q25", "q75", "min", "max"),
  #   sex = FALSE,
  #   ageGroup = NULL,
  #   dateRange = dateRange,
  #   conceptSummary = TRUE,
  #   missingData = TRUE,
  #   datasources = datasources
  # ))

  cli::cli_inform(paste(
    cli::symbol$arrow_right, "Summarising observation period"
  ))
  # NOT DEVELOPED [step 6] ds.summariseObservationPeriod
  #   (see summariseCustomObservationPeriod).
  # result$observationPeriod <- bindServers(ds.summariseObservationPeriod(
  #   cdm = cdm,
  #   sex = sex,
  #   ageGroup = ageGroup,
  #   dateRange = dateRange,
  #   datasources = datasources
  # ))

  cli::cli_inform(paste(
    cli::symbol$arrow_right, "Summarising observation period trends"
  ))
  # NOT DEVELOPED [step 8] ds.summariseTrend
  #   (see summariseCustomObservationPeriod).
  # result$trend <- bindServers(ds.summariseTrend(
  #   cdm = cdm,
  #   episode = "observation_period",
  #   event = "observation_period",
  #   output = "person-days",
  #   interval = interval,
  #   sex = FALSE,
  #   ageGroup = NULL,
  #   dateRange = dateRange,
  #   inObservation = inObservation,
  #   datasources = datasources
  # ))

  cli::cli_inform(paste(
    cli::symbol$arrow_right, "Summarising clinical records trends"
  ))
  # NOT DEVELOPED [step 8] ds.summariseTrend, server drops empty tables.
  # result$clinical_trend <- bindServers(ds.summariseTrend(
  #   cdm = cdm,
  #   event = omopTableName,
  #   output = "record",
  #   interval = interval,
  #   sex = FALSE,
  #   ageGroup = NULL,
  #   dateRange = dateRange,
  #   inObservation = inObservation,
  #   datasources = datasources
  # ))

  dur <- abs(as.numeric(Sys.time() - startTime, units = "secs"))
  cli::cli_inform(paste(
    cli::symbol$smiley, "Database characterisation finished. Code ran in",
    floor(dur / 60), "min and", dur %% 60 %/% 1, "sec"
  ))

  if (length(result) == 0) {
    return(NULL)
  }
  omopgenerics::bind(result)
}
