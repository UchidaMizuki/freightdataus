# cfs_pair_get() checks its arguments

    Code
      cfs_pair_get(c(2012, 2017))
    Condition
      Error in `cfs_pair_get()`:
      ! `year` must be a whole number, not a double vector.
    Code
      cfs_pair_get(2017, geography = "county")
    Condition
      Error in `cfs_pair_get()`:
      ! `geography` must be one of "state" or "cfs_area", not "county".

