# cfs_flow_target_raw() checks its arguments

    Code
      cfs_flow_target_raw(1, year = 2017)
    Condition
      Error in `cfs_flow_target_raw()`:
      ! `name` must be a single string, not the number 1.
    Code
      cfs_flow_target_raw("flow", year = 2015)
    Condition
      Error in `cfs_flow_target_raw()`:
      ! `year` must be one of 2012, 2017, or 2022, not 2015.
    Code
      cfs_flow_target_raw("flow", year = 2017, geography = "county")
    Condition
      Error in `cfs_flow_target_raw()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".
    Code
      cfs_flow_target_raw("flow", year = 2017, by_mode = NA)
    Condition
      Error in `cfs_flow_target_raw()`:
      ! `by_mode` must be `TRUE` or `FALSE`, not `NA`.

