# A fresh GiBleed CDM (omock, DuckDB) per call: unit tests never share state.
gibleedCdm <- function() {
  suppressMessages(omock::mockCdmFromDataset("GiBleed", source = "duckdb"))
}
