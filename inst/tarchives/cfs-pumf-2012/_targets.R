library(targets)
library(tarchives)

# sf registers the dplyr methods of the zone polygons.
tar_option_set(packages = "sf")

tar_source_archive("freightdataus")

tar_cfs_pumf(
  year = 2012,
  url_shipment = url_census(
    "programs-surveys/cfs/datasets/2012/2012-pums-files/cfs-2012-pumf-csv.zip"
  ),
  url_dictionary = url_census(
    "programs-surveys/cfs/datasets/2012/2012-pums-files/cfs-2012-pum-file-users-guide-app-a-jun2015.xlsx"
  ),
  sheet_commodity = "App A3",
  sheet_mode = "App A4",
  url_geography = url_census(
    "programs-surveys/cfs/technical-documentation/geographies/Shapefile of CFS Metro Areas for 2012 (requires ArcGIS to Open).zip"
  )
)
