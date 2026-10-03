library(targets)
library(tarchives)

# sf registers the dplyr methods of the zone polygons.
tar_option_set(packages = "sf")

tar_source_archive("freightdataus")

tar_cfs_pumf(
  year = 2017,
  url_shipment = url_census(
    "programs-surveys/cfs/datasets/2017/cfs-2017-puf-csv.zip"
  ),
  url_dictionary = url_census(
    "programs-surveys/cfs/datasets/2017/cfs-2017-puf-users-guide-app-a-aug2020.xlsx"
  ),
  sheet_commodity = "App A3",
  sheet_mode = "App A4",
  url_geography = url_census(
    "programs-surveys/cfs/technical-documentation/geographies/Shapefile of CFS Metro Areas for 2017 (requires ArcGIS to Open).zip"
  )
)
