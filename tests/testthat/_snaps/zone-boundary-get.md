# cfs_zone_boundary_get() checks its arguments

    Code
      cfs_zone_boundary_get(2020)
    Condition
      Error in `cfs_zone_boundary_get()`:
      ! `year` must be one of 2012, 2017, or 2022, not 2020.
    Code
      cfs_zone_boundary_get(2017, geography = "county")
    Condition
      Error in `cfs_zone_boundary_get()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".

