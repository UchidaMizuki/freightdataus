# cfs_zone_target_raw() checks its arguments

    Code
      cfs_zone_target_raw("zone", year = 2020)
    Condition
      Error in `cfs_zone_target_raw()`:
      ! `year` must be one of 2012, 2017, or 2022, not 2020.
    Code
      cfs_zone_target_raw("zone", year = 2017, geography = "county")
    Condition
      Error in `cfs_zone_target_raw()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".

