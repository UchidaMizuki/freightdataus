# cfs_flow_get() checks its arguments

    Code
      cfs_flow_get(2015)
    Condition
      Error in `cfs_flow_get()`:
      ! `year` must be one of 2012, 2017, or 2022, not 2015.
    Code
      cfs_flow_get("2017")
    Condition
      Error in `cfs_flow_get()`:
      ! `year` must be a whole number, not the string "2017".
    Code
      cfs_flow_get(2017, geography = "county")
    Condition
      Error in `cfs_flow_get()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".
    Code
      cfs_flow_get(2017, by_mode = NA)
    Condition
      Error in `cfs_flow_get()`:
      ! `by_mode` must be `TRUE` or `FALSE`, not `NA`.

