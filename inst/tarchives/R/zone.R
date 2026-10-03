# Zones are built from counties, so that every level and every year is
# handled the same way: a `get_county_zone_<geography>()` function assigns
# each county to a zone, `get_zone_boundary()` dissolves the county boundaries
# of the survey year, and `get_zone()` aggregates the county centers of
# population into the zone's center of population.

path_county_cfs_area <- "programs-surveys/cfs/technical-documentation/geographies/list2022.xlsx"

# County centers of population are published for every decennial census.
# The census nearest to the survey year is used (2010 for 2012, and 2020 for
# 2017 and 2022), so that no year is fixed.
url_county_population <- function(year) {
  census <- round(year / 10) * 10
  stringr::str_glue(
    "geo/docs/reference/cenpop{census}/county/CenPop{census}_Mean_CO.txt"
  ) |>
    url_census()
}

# Population and center of population of every county. The 2010 file is
# Latin-1 and the 2020 file UTF-8 with a byte order mark. Only ASCII columns
# are used, so both are read as Latin-1, and the columns are named by
# position rather than from the header. Coordinates are written with an
# explicit sign, such as "+61.191547".
read_file_county_population <- function(file) {
  duckplyr::read_csv_duckdb(
    file,
    prudence = "lavish",
    options = list(
      encoding = "latin-1",
      header = TRUE,
      names = list(c(
        "STATEFP",
        "COUNTYFP",
        "COUNAME",
        "STNAME",
        "POPULATION",
        "LATITUDE",
        "LONGITUDE"
      )),
      types = list(c(
        "VARCHAR",
        "VARCHAR",
        "VARCHAR",
        "VARCHAR",
        "DOUBLE",
        "DOUBLE",
        "DOUBLE"
      ))
    )
  ) |>
    dplyr::collect() |>
    dplyr::transmute(
      state_code = STATEFP,
      state_name = STNAME,
      county_code = stringr::str_c(STATEFP, COUNTYFP),
      population = POPULATION,
      longitude = LONGITUDE,
      latitude = LATITUDE
    )
}

# The geography file of each survey year has the TIGER/Line county and state
# boundaries that the CFS used, in layers named like "tl_2017_us_county" and
# "tl_2017_us_state". Unlike the TIGER files of the same year, the 2022 one
# keeps the Connecticut counties that the CFS used, rather than the planning
# regions.
read_file_county <- function(file) {
  dsn <- stringr::str_c("/vsizip/", file)
  layer <- sf::st_layers(dsn)$name
  state <- sf::read_sf(dsn, layer = stringr::str_subset(layer, "_us_state")) |>
    sf::st_drop_geometry() |>
    dplyr::select(state_code = STATEFP, state_name = NAME)

  sf::read_sf(dsn, layer = stringr::str_subset(layer, "_us_county")) |>
    sf::st_transform(4326) |>
    dplyr::select(state_code = STATEFP, county_code = GEOID) |>
    dplyr::left_join(state, by = "state_code") |>
    dplyr::relocate(state_name, .after = state_code)
}

# The list assigns every county to a CFS Area in every survey year, in the
# columns `CFS<yy>_AREA` and `CFS<yy>_NAME`. CFS Area names are taken from the
# list rather than from the users guides, because the 2012 data dictionary
# workbook omits the Albany CFS Area.
read_file_county_cfs_area <- function(file, year) {
  data <- readxl::read_excel(file, sheet = "CFSAreas", col_types = "text")
  column <- stringr::str_c(
    "CFS",
    stringr::str_sub(year, 3, 4),
    "_",
    c("AREA", "NAME")
  )
  tibble::tibble(
    state_code = stringr::str_pad(data$ST, 2, pad = "0"),
    county_code = stringr::str_c(
      state_code,
      stringr::str_pad(data$CNTY, 3, pad = "0")
    ),
    cfs_area_code = stringr::str_c(state_code, "-", data[[column[[1]]]]),
    cfs_area_name = stringr::str_squish(data[[column[[2]]]])
  )
}

# Counties of the states that the CFS covers, which leaves out the
# territories.
get_county_cfs <- function(county, county_cfs_area) {
  county |>
    sf::st_drop_geometry() |>
    dplyr::filter(state_code %in% county_cfs_area$state_code)
}

get_county_zone_state <- function(county, county_cfs_area) {
  get_county_cfs(county, county_cfs_area) |>
    dplyr::select(county_code, zone_code = state_code, zone_name = state_name)
}

# The list keeps both old and new codes of counties that changed. A county
# created after the survey year has no CFS Area in that year. It is assigned
# the only CFS Area of its state when there is exactly one, which holds for
# every such county (all are in Alaska or South Dakota).
get_county_zone_cfs_area <- function(county, county_cfs_area) {
  state_cfs_area <- county_cfs_area |>
    dplyr::filter(!is.na(cfs_area_code)) |>
    dplyr::distinct(state_code, cfs_area_code, cfs_area_name) |>
    dplyr::filter(dplyr::n() == 1, .by = state_code)

  county_zone <- get_county_cfs(county, county_cfs_area) |>
    dplyr::left_join(
      dplyr::select(county_cfs_area, !state_code),
      by = "county_code"
    ) |>
    dplyr::left_join(
      state_cfs_area,
      by = "state_code",
      suffix = c("", "_state")
    ) |>
    dplyr::transmute(
      county_code,
      zone_code = dplyr::coalesce(cfs_area_code, cfs_area_code_state),
      zone_name = dplyr::coalesce(cfs_area_name, cfs_area_name_state)
    )

  unassigned <- county_zone$county_code[is.na(county_zone$zone_code)]
  if (length(unassigned) > 0) {
    cli::cli_abort("Can't find the CFS Area of county {.val {unassigned}}.")
  }
  county_zone
}

# The representative point of a zone is its center of population, which is
# defined the same way for every level (unlike, for example, the principal
# city, which the remainders of states lack) and lies where people are. The
# county centers are aggregated with the formula that the Census Bureau uses
# for centers of population: the latitude is the population-weighted mean,
# and the longitude is weighted by population times the cosine of the
# latitude. Aggregated to states, it reproduces the published state centers.
#
# The formula is that of "Centers of Population Computation for the United
# States 1950-2020" (US Census Bureau, Geography Division, 2021), section
# "Method Used in Determining the 1960 to 2020 Centers of Population", which
# applies it to states and counties as well:
# https://www2.census.gov/geo/pdfs/reference/cenpop2020/COP2020_documentation.pdf
# The document converts eastern longitudes of the westernmost Aleutian
# Islands to below -180. This is not needed here, because the county centers
# are aggregates and all lie in the western hemisphere.
#
# `county_zone` assigns the counties of the census to zones, and the zones
# must be those of the boundaries of the survey year, whose names are used.
get_zone <- function(county_zone, county_population, zone_boundary) {
  zone <- county_zone |>
    dplyr::inner_join(
      dplyr::select(
        county_population,
        county_code,
        population,
        longitude,
        latitude
      ),
      by = "county_code"
    ) |>
    dplyr::mutate(weight_longitude = population * cos(latitude * pi / 180)) |>
    dplyr::summarise(
      longitude = sum(weight_longitude * longitude) / sum(weight_longitude),
      latitude = sum(population * latitude) / sum(population),
      .by = zone_code
    )

  only_census <- setdiff(zone$zone_code, zone_boundary$zone_code)
  only_boundary <- setdiff(zone_boundary$zone_code, zone$zone_code)
  if (length(only_census) > 0 || length(only_boundary) > 0) {
    cli::cli_abort(c(
      "The zones of the census differ from those of the boundaries.",
      i = if (length(only_census) > 0) {
        "Only in the census: {.val {only_census}}."
      },
      i = if (length(only_boundary) > 0) {
        "Only in the boundaries: {.val {only_boundary}}."
      }
    ))
  }

  zone_boundary |>
    sf::st_drop_geometry() |>
    dplyr::inner_join(zone, by = "zone_code") |>
    tibble::as_tibble()
}

get_zone_boundary <- function(county, county_zone) {
  county |>
    dplyr::inner_join(county_zone, by = "county_code") |>
    dplyr::group_by(zone_code, zone_name) |>
    dplyr::summarise(.groups = "drop") |>
    sf::st_cast("MULTIPOLYGON") |>
    check_zone() |>
    dplyr::arrange(zone_code)
}

check_zone <- function(zone) {
  if (vctrs::vec_duplicate_any(zone$zone_code)) {
    cli::cli_abort("Zones have more than one name.")
  }
  zone
}
