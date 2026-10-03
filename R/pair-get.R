#' Get distances between zones
#'
#' Returns distances for every ordered pair of zones of a survey year,
#' including pairs of a zone with itself.
#'
#' `distance_great_circle` and `distance_routed` are averages per shipment of
#' the shipment distances in the Public Use File: the sum of the weighting
#' factor times the distance, divided by the sum of the weighting factor, as
#' the users guides compute average miles per shipment. They are `NA` for
#' pairs without shipments, which are exactly the pairs without flows (about
#' 1% of the pairs). The 2022 file has no routed distance, so
#' `distance_routed` is `NA` for that year.
#'
#' Unlike a distance between representative points, the distance of a pair
#' of a zone with itself is the actual distance of the shipments within the
#' zone.
#'
#' @inheritParams cfs_flow_get
#'
#' @return A tibble with the columns:
#'
#' * `origin_code`, `destination_code`: Zone codes of the origin and
#'   destination.
#' * `distance_great_circle`: Average great-circle distance per shipment in
#'   km (a `units` column).
#' * `distance_routed`: Average routed distance per shipment in km.
#'
#' @export
#' @examples
#' \dontrun{
#' cfs_pair_get(2017)
#' }
cfs_pair_get <- function(year, geography = "state") {
  check_year(year)
  geography <- check_geography(geography)
  cfs_get(year, cfs_name_archive("pair", geography))
}
