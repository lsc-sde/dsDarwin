# dsDarwin Rock image: DataSHIELD Rock + what the DARWIN packages need + the
# dsDarwin server packages. Used twice in deploy/docker/docker-compose.yml: as
# the Rock R server and as the one-off delphi-setup loader, so the duckdb that
# writes the CDM file is the one Rock reads it with.
# Rock's R repo is a dated Posit snapshot (p3m.dev/.../2026-10-28): prebuilt
# binaries, same versions on every build. HERON's renv.lock pinning is #17.
# Build context: the repo root (see .dockerignore).
FROM datashield/rock-base:6.3.5-R4.6.1

RUN Rscript -e 'install.packages(c("duckdb", "CDMConnector", "CohortConstructor"))' \
 && Rscript -e 'stopifnot(requireNamespace("duckdb"), requireNamespace("CDMConnector"), requireNamespace("CohortConstructor"))'

# Server packages live in the image: Rock's R library is not on a volume and
# Opal refuses local installs (iteration 3). Opal still has to publish their
# methods once: opalr::dsadmin.publish_package() (examples/concept-cohort.R).
COPY helpers/dsDarwinHelpers/Server /tmp/dsDarwinHelpers
COPY dsCohortConstructor/Server /tmp/dsCohortConstructor
RUN R CMD INSTALL /tmp/dsDarwinHelpers /tmp/dsCohortConstructor \
 && rm -rf /tmp/dsDarwinHelpers /tmp/dsCohortConstructor \
 && Rscript -e 'stopifnot(requireNamespace("dsCohortConstructor"))'
