#' Declare a target that reads distances between zones
#'
#' For use inside a `_targets.R` pipeline, for example
#' `list(cfs_pair_target(pair, year = 2017))`. The target has the value of
#' [cfs_pair_get()]. See [cfs_flow_target()] for details.
#'
#' @inheritParams cfs_flow_target
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
#' @examples
#' cfs_pair_target(pair, year = 2017, geography = "cfs_area")
#' cfs_pair_target_raw("pair_2022", year = 2022)
cfs_pair_target <- function(name, year, geography = "state", ...) {
  cfs_pair_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    year = year,
    geography = geography,
    ...
  )
}

#' @rdname cfs_pair_target
#' @export
cfs_pair_target_raw <- function(name, year, geography = "state", ...) {
  rlang::check_string(name, allow_empty = FALSE)
  check_year(year)
  geography <- check_geography(geography)
  cfs_target(name, year, cfs_name_archive("pair", geography), ...)
}
