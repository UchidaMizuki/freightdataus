#' Get zones
#'
#' Returns the zones of a survey year with their representative points, for
#' example to compute spatial weights. See [cfs_zone_boundary_get()] for their
#' boundaries.
#'
#' The representative point of a zone is its center of population. It is
#' computed from the county centers of population that the Census Bureau
#' publishes for every decennial census, using the census nearest to the
#' survey year (2010 for 2012, and 2020 for 2017 and 2022), with the formula
#' that the Census Bureau uses for centers of population: the latitude is the
#' population-weighted mean of the county latitudes, and the longitude is
#' weighted by population times the cosine of the latitude. Aggregated to
#' states, it matches the state centers of population published by the Census
#' Bureau.
#'
#' The center of population is defined the same way for states, metro areas,
#' and the remainders of states, and it lies where people are. Like any
#' average, it can fall outside its zone: in the hole of a zone that surrounds
#' a metro area (such as "Remainder of Alabama", whose center is near
#' Birmingham) or in water (such as Mobile Bay).
#'
#' @inheritParams cfs_flow_get
#'
#' @references US Census Bureau, Geography Division (2021). *Centers of
#'   Population Computation for the United States 1950-2020*.
#'   <https://www2.census.gov/geo/pdfs/reference/cenpop2020/COP2020_documentation.pdf>
#'
#' @return A tibble with the columns:
#'
#' * `zone_code`: FIPS state code or CFS Area code.
#' * `zone_name`: Name of the state or of the CFS Area.
#' * `longitude`, `latitude`: Center of population of the zone in degrees.
#'
#' @export
#' @examples
#' \dontrun{
#' cfs_zone_get(2017, geography = "cfs_area")
#' }
cfs_zone_get <- function(year, geography = "state") {
  check_year(year)
  geography <- check_geography(geography)
  cfs_get(year, cfs_name_archive("zone", geography))
}
