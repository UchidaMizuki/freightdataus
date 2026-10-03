# get_county_zone_cfs_area() assigns a new county the only CFS Area of its state

    Code
      get_county_zone_cfs_area(fixture_county(), county_cfs_area)
    Condition
      Error in `get_county_zone_cfs_area()`:
      ! Can't find the CFS Area of county "49035".

# get_zone() errors when the zones differ from the boundaries

    Code
      get_zone(get_county_zone_state(county_population[-5, ], fixture_county_cfs_area(
        2017)), county_population = county_population, zone_boundary = zone_boundary)
    Condition
      Error in `get_zone()`:
      ! The zones of the census differ from those of the boundaries.
      i Only in the boundaries: "49".

