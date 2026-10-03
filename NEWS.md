# freightdataus (development version)

* Initial version with the Commodity Flow Survey Public Use File for 2012, 2017, and 2022.
* `cfs_flow_get()` returns weighted origin-destination flows between states or CFS Areas, by commodity and optionally by mode.
* `cfs_flow_target()`, `cfs_pair_target()`, `cfs_shipment_target()`, `cfs_zone_boundary_target()`, and `cfs_zone_target()` (and their `_raw()` variants) declare targets that read the data inside a targets pipeline.
* `cfs_pair_get()` returns distances between every pair of zones.
* `cfs_shipment_get()` returns the shipment records lazily as a duckplyr frame.
* `cfs_zone_boundary_get()` returns the boundaries of the states or CFS Areas as an sf data frame.
* `cfs_zone_get()` returns the states or CFS Areas with their centers of population.
