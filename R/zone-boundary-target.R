#' Declare a target that reads zone boundaries
#'
#' For use inside a `_targets.R` pipeline, for example
#' `list(cfs_zone_boundary_target(zone_boundary, year = 2017))`. The target
#' has the value of [cfs_zone_boundary_get()]. See [cfs_flow_target()] for
#' details.
#'
#' @inheritParams cfs_flow_target
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
#' @examples
#' cfs_zone_boundary_target(zone_boundary, year = 2017, geography = "cfs_area")
#' cfs_zone_boundary_target_raw("zone_boundary_2022", year = 2022)
cfs_zone_boundary_target <- function(name, year, geography = "state", ...) {
  cfs_zone_boundary_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    year = year,
    geography = geography,
    ...
  )
}

#' @rdname cfs_zone_boundary_target
#' @export
cfs_zone_boundary_target_raw <- function(
  name,
  year,
  geography = "state",
  ...
) {
  rlang::check_string(name, allow_empty = FALSE)
  check_year(year)
  geography <- check_geography(geography)
  cfs_target(name, year, cfs_name_archive("zone_boundary", geography), ...)
}
