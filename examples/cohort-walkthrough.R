# What CohortConstructor does, one person at a time, on GiBleed.
# Run: Rscript examples/cohort-walkthrough.R
suppressMessages({
  library(dplyr)
  library(CohortConstructor)
  library(omopgenerics)
})


# Or use the CDM connector to connect to the database
cdm <- omock::mockCdmFromDataset("GiBleed", source = "duckdb")
who <- 3115L #  any person_id

cat("\n== 1. Raw OMOP data for person", who, "(CohortConstructor never changes this) ==\n")
cdm$person |>
  filter(person_id == who) |>
  select(person_id, gender_concept_id, year_of_birth) |>
  collect() |>
  print()
  
cdm$observation_period |>
  filter(person_id == who) |>
  select(person_id, observation_period_start_date, observation_period_end_date) |>
  collect() |>
  print()
  
cdm$condition_occurrence |>
  filter(person_id == who, condition_concept_id == 192671L) |>
  select(person_id, condition_concept_id, condition_start_date) |>
  collect() |>
  print()

cdm$drug_exposure |> 
  filter(person_id == who, drug_concept_id == 1118084L) |>
  select(person_id, drug_exposure_start_date,drug_exposure_end_date) |>
  collect() |>
  print() # Table exposure of the drug

cat("\n== 2. demographicsCohort: who is in the data, and for how long ==\n")
cdm$population <- demographicsCohort(cdm, "population", sex = "Both")
cdm$population |>
  filter(subject_id == who) |>
  collect() |>
  print()

cat("\n== 3. trimToDateRange: only time from 2012 onwards counts ==\n")
cdm$population <- trimToDateRange(cdm$population, dateRange = as.Date(c("2012-01-01", NA)))
cdm$population |>
  filter(subject_id == who) |>
  collect() |>
  print() # 0 rows = dropped

cat("\n== 4. conceptCohort: people with a GI bleed, from the day of the bleed ==\n")
cdm$gibleed <- conceptCohort(cdm, conceptSet = list(gi_bleed = 192671L), name = "gibleed")
cdm$gibleed |>
  filter(subject_id == who) |>
  collect() |>
  print()

cat("\n== 4b. conceptCohort with a drug code: people taking celecoxib ==\n")
cdm$celecoxib <- conceptCohort(cdm, conceptSet = list(celecoxib = 1118084L), name = "celecoxib")
cdm$celecoxib |>
  filter(subject_id == who) |>
  collect() |>
  print()

cat("\n== 5. What we can move to the server ==\n")
print(settings(cdm$gibleed))
print(cohortCount(cdm$gibleed))
print(attrition(cdm$population) |> select(reason, number_subjects, excluded_subjects))
