library(targets)
library(tarchives)

# sf registers the dplyr methods of the zone polygons.
tar_option_set(packages = "sf")

tar_source_archive("freightdataus")

tar_cfs_pumf(
  year = 2022,
  url_shipment = url_census(
    "programs-surveys/cfs/datasets/2022/cfs_2022_pums.zip"
  ),
  url_dictionary = url_census(
    "programs-surveys/cfs/datasets/2022/cfs_2022_pums_data_dictionary.xlsx"
  ),
  url_geography = url_census(
    "programs-surveys/cfs/technical-documentation/geographies/2022_CFS_Areas.zip"
  )
)
