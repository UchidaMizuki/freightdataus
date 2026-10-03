#' Declare a target that reads origin-destination flows
#'
#' For use inside a `_targets.R` pipeline, for example
#' `list(cfs_flow_target(flow, year = 2017))`. The target has the value of
#' [cfs_flow_get()]. The data are built when the target runs, not when the
#' pipeline is defined, and the target reruns when a new version of
#' freightdataus is installed.
#'
#' `cfs_flow_target()` captures `name` with non-standard evaluation, mirroring
#' [tarchives::tar_target_archive()]. `cfs_flow_target_raw()` takes `name` as
#' a string instead, for programmatic use such as declaring a target for
#' every year in a loop, mirroring [tarchives::tar_target_archive_raw()].
#'
#' @param name Symbol (`cfs_flow_target()`) or string (`cfs_flow_target_raw()`),
#'   name of the target.
#' @inheritParams cfs_flow_get
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
#' @examples
#' cfs_flow_target(flow, year = 2017, geography = "cfs_area")
#' cfs_flow_target_raw("flow_2022", year = 2022, by_mode = TRUE)
cfs_flow_target <- function(
  name,
  year,
  geography = "state",
  by_mode = FALSE,
  ...
) {
  cfs_flow_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    year = year,
    geography = geography,
    by_mode = by_mode,
    ...
  )
}

#' @rdname cfs_flow_target
#' @export
cfs_flow_target_raw <- function(
  name,
  year,
  geography = "state",
  by_mode = FALSE,
  ...
) {
  rlang::check_string(name, allow_empty = FALSE)
  check_year(year)
  geography <- check_geography(geography)
  rlang::check_bool(by_mode)
  cfs_target(name, year, cfs_name_archive("flow", geography, by_mode), ...)
}
