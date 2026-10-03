# Creates the fixture files that are not written by hand. Run from
# tests/testthat/fixtures. Needs the network, curl, dplyr, fs, purrr, readxl,
# sf, writexl, and zip.

base <- "https://www2.census.gov/programs-surveys/cfs"

# Data dictionaries, as published.
curl::curl_download(
  fs::path(
    base,
    "datasets/2012/2012-pums-files/cfs-2012-pum-file-users-guide-app-a-jun2015.xlsx"
  ),
  "dictionary-2012.xlsx"
)
curl::curl_download(
  fs::path(base, "datasets/2017/cfs-2017-puf-users-guide-app-a-aug2020.xlsx"),
  "dictionary-2017.xlsx"
)
curl::curl_download(
  fs::path(base, "datasets/2022/cfs_2022_pums_data_dictionary.xlsx"),
  "dictionary-2022.xlsx"
)

# A few counties of the county-to-CFS Area list: Anchorage and Chugach (which
# has no CFS Area before 2022), Kern and Los Angeles, and Salt Lake.
file <- fs::file_temp(ext = "xlsx")
curl::curl_download(
  fs::path(base, "technical-documentation/geographies/list2022.xlsx"),
  file
)
county_cfs_area <- readxl::read_excel(file, sheet = "CFSAreas")
county_cfs_area <- county_cfs_area[
  stringr::str_c(county_cfs_area$ST, county_cfs_area$CNTY) %in%
    c("0220", "0263", "0629", "0637", "4935"),
]
writexl::write_xlsx(list(CFSAreas = county_cfs_area), "county-cfs-area.xlsx")
fs::file_delete(file)

# Centers of population of the same counties, and one in Puerto Rico, keeping
# the byte order mark of the 2020 file.
file <- fs::file_temp(ext = "txt")
curl::curl_download(
  "https://www2.census.gov/geo/docs/reference/cenpop2020/county/CenPop2020_Mean_CO.txt",
  file
)
lines <- readLines(file, encoding = "UTF-8")
lines <- lines[
  c(
    TRUE,
    stringr::str_detect(
      lines[-1],
      "^(02,020|02,063|06,029|06,037|49,035|72,001),"
    )
  )
]
# readLines() drops the byte order mark, so it is written back as bytes.
con <- file("county-population.txt", "wb")
writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
writeLines(lines, con, sep = "\n", useBytes = TRUE)
close(con)
fs::file_delete(file)

# The same counties, and one in Puerto Rico, as squares one degree wide in the
# layout of the geography file of a survey year: TIGER/Line county and state
# layers in one zip file.
county <- tibble::tribble(
  ~STATEFP , ~NAME         , ~GEOID  , ~longitude , ~latitude ,
  "02"     , "Alaska"      , "02020" , -149.5     , 61.5      ,
  "02"     , "Alaska"      , "02063" , -145.5     , 61.5      ,
  "06"     , "California"  , "06029" , -118.5     , 35.5      ,
  "06"     , "California"  , "06037" , -117.5     , 34.5      ,
  "49"     , "Utah"        , "49035" , -111.5     , 40.5      ,
  "72"     , "Puerto Rico" , "72001" ,  -66.5     , 18.5
)
county$geometry <- purrr::map2(county$longitude, county$latitude, \(x, y) {
  sf::st_polygon(list(cbind(
    x + c(-0.5, 0.5, 0.5, -0.5, -0.5),
    y + c(-0.5, -0.5, 0.5, 0.5, -0.5)
  )))
}) |>
  sf::st_sfc(crs = 4269)
county <- sf::st_sf(county[c("STATEFP", "NAME", "GEOID", "geometry")])
state <- county |>
  dplyr::group_by(STATEFP, NAME) |>
  dplyr::summarise(.groups = "drop")

dir <- fs::dir_create(fs::file_temp())
sf::write_sf(
  dplyr::select(county, STATEFP, GEOID),
  fs::path(dir, "tl_2017_us_county.shp")
)
sf::write_sf(state, fs::path(dir, "tl_2017_us_state.shp"))
zip::zip("geography.zip", fs::dir_ls(dir), mode = "cherry-pick")
fs::dir_delete(dir)

zip::zip("puf-2017.zip", "puf-2017.csv")
