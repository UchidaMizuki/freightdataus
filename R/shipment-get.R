#' Get shipment records
#'
#' Returns the shipment records of the Commodity Flow Survey (CFS) Public Use
#' File of one survey year as a lazy duckplyr frame backed by a Parquet file.
#' The data are downloaded and converted the first time they are requested.
#'
#' The table is never loaded into memory as a whole. Use dplyr verbs to filter
#' or aggregate it, and [dplyr::collect()] to bring a small result into memory.
#' Weighted totals are the sum of `weighting_factor` times the variable, as
#' the CFS users guides specify.
#'
#' The columns are the same in every year. A variable that a year lacks is an
#' all-`NA` column: `naics_code`, `quarter`, and `distance_routed` in 2022, and
#' `sector_code` in 2012 and 2017. Codes are kept as published, and they
#' differ between years: for example, the mode codes of 2022 are not those of
#' 2012 and 2017. See the users guide of each year for the code lists.
#'
#' @inheritParams cfs_flow_get
#'
#' @return A duckplyr frame with one row per shipment record and the columns:
#'
#' * `year`: Survey year.
#' * `shipment_id`: Shipment identifier (`SHIPMT_ID`).
#' * `origin_state_code`, `origin_metro_code`, `origin_cfs_area_code`: Origin
#'   state (FIPS code), metro area, and CFS Area (`ORIG_STATE`, `ORIG_MA`,
#'   `ORIG_CFS_AREA`). A suppressed origin is coded `"00"` (state) and
#'   `"00000"` (metro area).
#' * `destination_state_code`, `destination_metro_code`,
#'   `destination_cfs_area_code`: Destination state, metro area, and CFS Area
#'   (`DEST_STATE`, `DEST_MA`, `DEST_CFS_AREA`).
#' * `naics_code`: NAICS industry of the shipper (`NAICS`).
#' * `sector_code`: NAICS sector of the shipper (`SECTOR`).
#' * `quarter`: Quarter of the shipment (`QUARTER`).
#' * `commodity_code`: SCTG commodity code (`SCTG`).
#' * `mode_code`: Mode of transportation (`MODE`).
#' * `value_usd`: Value of the shipment in US dollars (`SHIPMT_VALUE`).
#' * `weight`: Weight of the shipment in pounds (`SHIPMT_WGHT`).
#' * `distance_great_circle`: Great-circle distance between origin and
#'   destination in miles (`SHIPMT_DIST_GC`).
#' * `distance_routed`: Routed distance between origin and destination in
#'   miles (`SHIPMT_DIST_ROUTED`).
#' * `temperature_controlled`: Whether the shipment was temperature
#'   controlled (`TEMP_CNTL_YN`).
#' * `export`: Whether the shipment was an export (`EXPORT_YN`).
#' * `export_destination_code`: Final export destination (`EXPORT_CNTRY`).
#' * `hazmat_code`: Hazardous material code (`HAZMAT`).
#' * `weighting_factor`: Shipment tabulation weighting factor (`WGT_FACTOR`),
#'   which is also an estimate of the number of shipments that the record
#'   represents.
#'
#' The quantities are plain numbers in the units of the Public Use File,
#' because the table is lazy.
#'
#' @export
#' @examples
#' \dontrun{
#' shipment <- cfs_shipment_get(2017)
#'
#' shipment |>
#'   dplyr::summarise(
#'     value_usd = sum(weighting_factor * value_usd),
#'     .by = mode_code
#'   ) |>
#'   dplyr::collect()
#' }
cfs_shipment_get <- function(year) {
  check_year(year)
  duckplyr::read_parquet_duckdb(cfs_get(year, cfs_name_archive("shipment")))
}
