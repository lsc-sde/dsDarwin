# dsDarwin Rock image: DataSHIELD Rock + what the DARWIN packages need.
# Used twice in deploy/docker/docker-compose.yml: as the Rock R server and as
# the one-off delphi-setup loader, so the duckdb that writes the CDM file is the
# Rock's R repo is a dated Posit snapshot (p3m.dev/.../2026-10-28): prebuilt
# binaries, same versions on every build. HERON's renv.lock pinning is #17.
FROM datashield/rock-base:6.3.5-R4.6.1

RUN Rscript -e 'install.packages(c("duckdb", "CDMConnector"))' \
 && Rscript -e 'stopifnot(requireNamespace("duckdb"), requireNamespace("CDMConnector"))'
