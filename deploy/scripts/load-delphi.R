# One-off loader for the delphi-setup service. CDMConnector downloads
Sys.setenv(EUNOMIA_DATA_FOLDER = "/data")
# eunomiaDir() returns a temp copy of the file; we use the cached one.
unlink(CDMConnector::eunomiaDir("delphi-100k", "5.4"))

link <- "/data/delphi-100k.duckdb"
if (!file.exists(link)) {
  built <- list.files("/data", "^delphi-100k_5\\.4_.*\\.duckdb$")
  file.symlink(tail(built, 1), link)
}
