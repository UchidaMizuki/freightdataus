# Columns of the shipment table, in order, with the PUF variable that each
# one comes from and its type. The columns are the union over all years: a
# variable that a year's file lacks becomes an all-NA column of the same type.
shipment_spec <- tibble::tribble(
  ~column                     , ~variable            , ~type       ,
  "shipment_id"               , "SHIPMT_ID"          , "character" ,
  "origin_state_code"         , "ORIG_STATE"         , "character" ,
  "origin_metro_code"         , "ORIG_MA"            , "character" ,
  "origin_cfs_area_code"      , "ORIG_CFS_AREA"      , "character" ,
  "destination_state_code"    , "DEST_STATE"         , "character" ,
  "destination_metro_code"    , "DEST_MA"            , "character" ,
  "destination_cfs_area_code" , "DEST_CFS_AREA"      , "character" ,
  "naics_code"                , "NAICS"              , "character" ,
  "sector_code"               , "SECTOR"             , "character" ,
  "quarter"                   , "QUARTER"            , "integer"   ,
  "commodity_code"            , "SCTG"               , "character" ,
  "mode_code"                 , "MODE"               , "character" ,
  "value_usd"                 , "SHIPMT_VALUE"       , "double"    ,
  "weight"                    , "SHIPMT_WGHT"        , "double"    ,
  "distance_great_circle"     , "SHIPMT_DIST_GC"     , "double"    ,
  "distance_routed"           , "SHIPMT_DIST_ROUTED" , "double"    ,
  "temperature_controlled"    , "TEMP_CNTL_YN"       , "logical"   ,
  "export"                    , "EXPORT_YN"          , "logical"   ,
  "export_destination_code"   , "EXPORT_CNTRY"       , "character" ,
  "hazmat_code"               , "HAZMAT"             , "character" ,
  "weighting_factor"          , "WGT_FACTOR"         , "double"
)

# Convert the zipped PUF CSV file to Parquet without loading it into memory.
# The CSV file is extracted to a temporary directory that is deleted
# afterwards, since the 2022 file alone is 2.8 GB.
write_shipment <- function(file, year) {
  dir <- fs::file_temp()
  withr::defer(fs::dir_delete(dir))
  csv <- utils::unzip(file, exdir = dir)

  path <- path_user("shipment.parquet")
  read_csv_shipment(csv) |>
    clean_shipment(year = year) |>
    duckplyr::compute_parquet(path)
  as.character(path)
}

read_csv_shipment <- function(file) {
  header <- duckplyr::read_csv_duckdb(
    file,
    options = list(all_varchar = TRUE)
  ) |>
    colnames()
  unknown <- setdiff(header, shipment_spec$variable)
  if (length(unknown) > 0) {
    cli::cli_abort("Unknown PUF variable{?s}: {.val {unknown}}.")
  }

  double <- shipment_spec$variable[shipment_spec$type == "double"]
  types <- dplyr::if_else(header %in% double, "DOUBLE", "VARCHAR") |>
    rlang::set_names(header)
  duckplyr::read_csv_duckdb(
    file,
    prudence = "stingy",
    options = list(types = list(types))
  )
}

clean_shipment <- function(data, year) {
  # DuckDB column names are case-insensitive, so `QUARTER` would clash with
  # `quarter`.
  data <- dplyr::rename(
    data,
    dplyr::all_of(rlang::set_names(colnames(data), \(x) {
      stringr::str_c("puf_", x)
    }))
  )

  # The expressions are built from symbols, because duckplyr cannot translate
  # `.data[[variable]]` or `across()` to DuckDB.
  exprs <- purrr::pmap(shipment_spec, function(column, variable, type) {
    variable <- stringr::str_c("puf_", variable)
    if (!variable %in% colnames(data)) {
      return(shipment_missing[[type]])
    }

    variable <- rlang::sym(variable)
    switch(
      type,
      integer = rlang::expr(as.integer(!!variable)),
      logical = rlang::expr(
        dplyr::if_else(
          !!variable == "Y",
          TRUE,
          dplyr::if_else(!!variable == "N", FALSE, NA)
        )
      ),
      variable
    )
  }) |>
    rlang::set_names(shipment_spec$column)

  dplyr::transmute(data, year = as.integer(.env$year), !!!exprs)
}

shipment_missing <- list(
  character = NA_character_,
  integer = NA_integer_,
  double = NA_real_,
  logical = NA
)

# Shipment records with the origin and destination codes of `geography`,
# leaving out records whose origin is suppressed at that level (see
# `geography_spec`).
read_shipment_zone <- function(shipment, geography) {
  spec <- vctrs::vec_slice(
    geography_spec,
    vctrs::vec_match(geography, geography_spec$geography)
  )
  duckplyr::read_parquet_duckdb(shipment, prudence = "stingy") |>
    dplyr::filter(
      !!rlang::sym(spec$suppressed_column) != !!spec$suppressed_code
    ) |>
    dplyr::rename(
      origin_code = !!stringr::str_c("origin_", geography, "_code"),
      destination_code = !!stringr::str_c("destination_", geography, "_code")
    )
}
