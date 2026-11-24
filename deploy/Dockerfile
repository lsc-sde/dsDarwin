# Build from the repository root. See .dockerignore for the files sent to Docker.
# Compose uses this image for Rock and the one-off Delphi loader so both use
# the same DuckDB version to read and write the CDM file.
FROM datashield/rock-base:6.3.5-R4.6.1

# The base image tag pins R. The pins below reproduce the HERON results on
# Delphi-100k obtained with the study's renv.lock (iteration 9, #17).
# pak requires the specified versions. It resolves unpinned
# CRAN dependencies against Rock's dated Posit snapshot (2026-10-28).
# The list covers every DARWIN package HERON uses, wrapped or not yet. Wrapping
# one not listed here? Pin it too: install-server-packages.R installs missing
# imports at the snapshot's version.
RUN Rscript -e 'pak::pak(c( \
      "CohortConstructor@0.6.3", "CDMConnector@2.8.0", "omopgenerics@1.4.2", \
      "PatientProfiles@1.6.1", "CohortCharacteristics@1.1.3", \
      "OmopConstructor@0.3.0", "OmopSketch@1.1.1", "duckdb@2.0.0"))'

# Bake server packages into Rock so deployments carry their own R library.
# The installer discovers packages under ds*/Server and helpers/*/Server.
# Publish their DataSHIELD methods in Opal after deployment. See
# opalr::dsadmin.publish_package() in examples/concept-cohort.R.
COPY . /tmp/dsdarwin
RUN Rscript /tmp/dsdarwin/deploy/scripts/install-server-packages.R /tmp/dsdarwin \
 && rm -rf /tmp/dsdarwin
