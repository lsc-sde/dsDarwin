# Use the repository root as the build context. .dockerignore limits which
# files Docker receives.
# Rock and the Delphi loader share this image so they use the same DuckDB
# version to read and write the Delphi-100k database.
FROM datashield/rock-base:6.3.5-R4.6.1

# The Rock base image sets the R version. Pin the packages used by HERON to
# the versions tested on Delphi-100k with the study's renv.lock (issue #17).
# The list includes packages that dsDarwin has yet to wrap. When adding a
# wrapper for another HERON package, add its tested version here.
# Unpinned CRAN dependencies come from Rock's 2026-10-28 Posit snapshot.
RUN Rscript -e 'pak::pak(c( \
      "CohortConstructor@0.6.3", "CDMConnector@2.8.0", "omopgenerics@1.4.2", \
      "PatientProfiles@1.6.1", "CohortCharacteristics@1.1.3", \
      "OmopConstructor@0.3.0", "OmopSketch@1.1.1", "duckdb@2.0.0"))'

# Install the local R packages under ds*/Server and helpers/*/Server into
# the image so Rock can load them at runtime. The installer handles package
# dependencies and checks that each server package loads.
# After deployment, publish the DataSHIELD methods in Opal with
# opalr::dsadmin.publish_package(). See examples/concept-cohort.R.
COPY . /tmp/dsdarwin
RUN Rscript /tmp/dsdarwin/deploy/scripts/install-server-packages.R /tmp/dsdarwin \
 && rm -rf /tmp/dsdarwin
