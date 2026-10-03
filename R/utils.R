# Zone levels. They must match `geography_spec` in
# inst/tarchives/R/geography.R, which a test checks.
cfs_geographies <- c("state", "cfs_area")

# Read a target of the pipeline of `year`, building it first if needed. Kept
# separate from the getters so that tests can mock it.
cfs_get <- function(year, name_archive) {
  tarchives::tar_get_archive_raw(
    name = name_archive,
    package = "freightdataus",
    pipeline = cfs_pipeline(year)
  )
}

# Declare a target that reads a target of the pipeline of `year`.
cfs_target <- function(name, year, name_archive, ...) {
  tarchives::tar_target_archive_raw(
    name = name,
    package = "freightdataus",
    pipeline = cfs_pipeline(year),
    name_archive = name_archive,
    ...
  )
}

cfs_pipeline <- function(year) {
  stringr::str_c("cfs-pumf-", year)
}

# Name of a target of the pipelines, for example "flow_cfs_area_mode".
cfs_name_archive <- function(object, geography = NULL, by_mode = FALSE) {
  stringr::str_flatten(c(object, geography, if (by_mode) "mode"), "_")
}

# Survey years, from the pipelines bundled in inst/tarchives, so that adding a
# pipeline is enough to add a year.
cfs_years <- function() {
  pipelines <- tarchives::tar_archive_pipelines("freightdataus")
  years <- stringr::str_match(pipelines, "^cfs-pumf-(\\d{4})$")[, 2]
  as.integer(years[!is.na(years)])
}

check_year <- function(
  year,
  arg = rlang::caller_arg(year),
  call = rlang::caller_env()
) {
  rlang::check_number_whole(year, arg = arg, call = call)
  years <- cfs_years()
  if (!year %in% years) {
    cli::cli_abort(
      "{.arg {arg}} must be one of {.or {years}}, not {year}.",
      call = call
    )
  }
  invisible()
}

check_geography <- function(
  geography,
  arg = rlang::caller_arg(geography),
  call = rlang::caller_env()
) {
  rlang::arg_match(
    geography,
    cfs_geographies,
    error_arg = arg,
    error_call = call
  )
}
