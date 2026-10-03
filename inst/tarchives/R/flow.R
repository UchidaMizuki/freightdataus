# Weighted origin-destination flows. Weighted totals are the sum of
# WGT_FACTOR times the variable, as the users guides specify, so
# `n_shipments` (the sum of WGT_FACTOR) is the weighted number of shipments
# and `n_records` is the unweighted number of records.
get_flow <- function(
  shipment,
  year,
  geography,
  by_mode,
  dictionary_commodity,
  dictionary_mode
) {
  keys <- c(
    "commodity_code",
    "origin_code",
    "destination_code",
    if (by_mode) "mode_code"
  )
  flow <- read_shipment_zone(shipment, geography) |>
    dplyr::summarise(
      weight = sum(weighting_factor * weight),
      value_usd = sum(weighting_factor * value_usd),
      n_shipments = sum(weighting_factor),
      n_records = dplyr::n(),
      .by = dplyr::all_of(keys)
    ) |>
    dplyr::collect() |>
    join_code_name(dictionary_commodity, "commodity")
  if (by_mode) {
    flow <- join_code_name(flow, dictionary_mode, "mode")
  }

  flow |>
    dplyr::mutate(
      year = as.integer(year),
      weight = set_units_from(weight, "lb", "t"),
      n_records = as.integer(n_records)
    ) |>
    dplyr::select(
      "year",
      dplyr::all_of(keys),
      "commodity_name",
      dplyr::any_of("mode_name"),
      "weight",
      "value_usd",
      "n_shipments",
      "n_records"
    ) |>
    dplyr::arrange(dplyr::pick(dplyr::all_of(keys)))
}

# The 2012 and 2017 dictionaries list no names for SCTG groups (for example
# "01-05"), which the PUF uses where commodity detail was collapsed. Their
# names are left missing; any other code without a name is an error.
join_code_name <- function(data, dictionary, object) {
  code <- stringr::str_c(object, "_code")
  name <- stringr::str_c(object, "_name")
  data <- dplyr::left_join(data, dictionary, by = code)

  unnamed <- data[[code]][is.na(data[[name]])] |>
    unique() |>
    purrr::discard(
      \(x) object == "commodity" && stringr::str_detect(x, "^\\d{2}-\\d{2}$")
    )
  if (length(unnamed) > 0) {
    cli::cli_abort("Can't find the name of {object} code{?s} {.val {unnamed}}.")
  }
  data
}
