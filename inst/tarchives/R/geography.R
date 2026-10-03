# Zone levels. Everything that depends on the level is derived from this
# table, so adding or refining a level means adding a row here and a
# `get_county_zone_<geography>()` function in zone.R:
#
# * The shipment table has `origin_<geography>_code` and
#   `destination_<geography>_code` columns.
# * A record whose origin is suppressed at the level has `suppressed_code` in
#   `suppressed_column`. Such records are left out of the flows and pairs.
geography_spec <- tibble::tribble(
  ~geography , ~suppressed_column  , ~suppressed_code ,
  "state"    , "origin_state_code" , "00"             ,
  "cfs_area" , "origin_metro_code" , "00000"
)
