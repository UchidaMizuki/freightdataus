#' Get origin-destination flows
#'
#' Returns weighted freight flows between zones, by commodity and optionally
#' by mode, tabulated from the shipment records of the Commodity Flow Survey
#' (CFS) Public Use File. The data are built the first time they are
#' requested.
#'
#' Weighted totals are the sum of the weighting factor times the variable, as
#' the CFS users guides specify. Records whose origin is suppressed at the
#' requested geography are left out, so the totals over all zones can fall
#' short of the national totals.
#'
#' Commodity and mode codes are kept as published, including the collapsed
#' codes that the Public Use File uses for confidentiality: SCTG groups such
#' as `"01-05"`, suppressed commodities (`"00"`), and less detailed or
#' suppressed modes. The 2012 and 2017 users guides give no names for SCTG
#' groups, so their `commodity_name` is `NA`. The mode codes of 2022 differ
#' from those of 2012 and 2017.
#'
#' @param year Survey year: 2012, 2017, or 2022.
#' @param geography Zones of the origin and destination: `"state"` or
#'   `"cfs_area"`. CFS Areas are metropolitan areas and the remainders of
#'   states. Their boundaries change between survey years, so the set of codes
#'   differs by year.
#' @param by_mode Whether to tabulate by mode of transportation as well.
#'
#' @return A tibble with the columns:
#'
#' * `year`: Survey year.
#' * `commodity_code`: SCTG commodity code.
#' * `origin_code`, `destination_code`: Zone codes of the origin and
#'   destination: the FIPS state code (for example `"06"`) or the CFS Area
#'   code (for example `"06-348"`).
#' * `mode_code`: Mode of transportation, if `by_mode = TRUE`.
#' * `commodity_name`: Name of the commodity.
#' * `mode_name`: Name of the mode, if `by_mode = TRUE`.
#' * `weight`: Weighted total weight in metric tonnes (a `units` column).
#' * `value_usd`: Weighted total value in US dollars.
#' * `n_shipments`: Weighted number of shipments.
#' * `n_records`: Unweighted number of shipment records.
#'
#' @export
#' @examples
#' \dontrun{
#' cfs_flow_get(2017)
#' cfs_flow_get(2017, geography = "cfs_area", by_mode = TRUE)
#' }
cfs_flow_get <- function(
  year,
  geography = "state",
  by_mode = FALSE
) {
  check_year(year)
  geography <- check_geography(geography)
  rlang::check_bool(by_mode)
  cfs_get(year, cfs_name_archive("flow", geography, by_mode))
}
