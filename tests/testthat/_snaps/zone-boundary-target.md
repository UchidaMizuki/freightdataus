# cfs_zone_boundary_target_raw() checks its arguments

    Code
      cfs_zone_boundary_target_raw("zone_boundary", year = 2017, geography = "county")
    Condition
      Error in `cfs_zone_boundary_target_raw()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".

