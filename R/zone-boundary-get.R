#' Get zone boundaries
#'
#' Returns the boundaries of the zones of a survey year, for example to map
#' flows or to find adjacent zones. They are built by dissolving the TIGER/Line
#' counties of the CFS geography file of the survey year with the
#' county-to-CFS Area list of the Census Bureau, in the same way for every
#' year. TIGER/Line boundaries include water areas, such as coastal waters and
#' the Great Lakes. See [cfs_zone_get()] for the representative points of the
#' zones.
#'
#' @inheritParams cfs_flow_get
#'
#' @return An sf data frame with the columns:
#'
#' * `zone_code`: FIPS state code or CFS Area code.
#' * `zone_name`: Name of the state or of the CFS Area.
#' * `geometry`: Boundary of the zone (`MULTIPOLYGON`, WGS 84).
#'
#' @export
#' @examples
#' \dontrun{
#' cfs_zone_boundary_get(2017, geography = "cfs_area")
#' }
cfs_zone_boundary_get <- function(year, geography = "state") {
  rlang::check_installed("sf", reason = "to read zone boundaries.")
  check_year(year)
  geography <- check_geography(geography)
  cfs_get(year, cfs_name_archive("zone_boundary", geography))
}
