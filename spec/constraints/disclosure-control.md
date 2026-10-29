# Disclosure control

What server functions may send back to the analyst. Which suppression rule aggregates apply (omopgenerics `minCellCount` vs DataSHIELD `nfilter.*`) is still open: issue #16.

- Server functions never return row-level data to the client. Assign functions return nothing.
- Every aggregate function checks its output against the DataSHIELD disclosure thresholds (`nfilter.*`) before returning it.
- Read thresholds the dsBase way: `getOption("nfilter.tab")`, falling back to `getOption("default.nfilter.tab")`.
  Don't redeclare `nfilter.*` under `Options:` in `inst/DATASHIELD`; they come from dsBase. Declare only options this package introduces.
- Error and warning messages reach the analyst: never put data values in them.
