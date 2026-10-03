#' Declare a target that tracks the shipment records
#'
#' For use inside a `_targets.R` pipeline, for example
#' `list(cfs_shipment_target(shipment, year = 2017))`. Unlike
#' [cfs_shipment_get()], the target does not hold the records, which would
#' load them into memory. Its value is the path of the Parquet file of the
#' records, tracked as a file (`format = "file"`), so downstream targets rerun
#' when the records change. Read it lazily with
#' [duckplyr::read_parquet_duckdb()]. See [cfs_flow_target()] for details.
#'
#' @inheritParams cfs_flow_target
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()], except
#'   `format`.
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
#' @examples
#' cfs_shipment_target(shipment, year = 2017)
#' cfs_shipment_target_raw("shipment_2022", year = 2022)
cfs_shipment_target <- function(name, year, ...) {
  cfs_shipment_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    year = year,
    ...
  )
}

#' @rdname cfs_shipment_target
#' @export
cfs_shipment_target_raw <- function(name, year, ...) {
  rlang::check_string(name, allow_empty = FALSE)
  check_year(year)
  cfs_target(name, year, cfs_name_archive("shipment"), ..., format = "file")
}
