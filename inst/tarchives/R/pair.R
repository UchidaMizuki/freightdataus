# Distances between every pair of zones, from the shipment distances of the
# PUF. They are averaged per shipment, as the users guides compute average
# miles per shipment: the sum of WGT_FACTOR times the distance, divided by the
# sum of WGT_FACTOR. Pairs without shipments get `NA`, which are exactly the
# pairs without flows.
#
# This is `weighted.mean(distance, weighting_factor)`, which DuckDB cannot
# run, so the sums are computed in DuckDB and divided in R. As in
# `weighted.mean()`, a missing distance makes the mean missing, because
# duckplyr's `sum()` keeps R's semantics.
get_pair <- function(shipment, zone, geography) {
  distance <- read_shipment_zone(shipment, geography) |>
    dplyr::summarise(
      n_shipments = sum(weighting_factor),
      distance_great_circle = sum(weighting_factor * distance_great_circle),
      distance_routed = sum(weighting_factor * distance_routed),
      .by = c(origin_code, destination_code)
    ) |>
    dplyr::collect() |>
    dplyr::mutate(
      dplyr::across(
        c(distance_great_circle, distance_routed),
        \(x) dplyr::if_else(n_shipments > 0, x / n_shipments, NA)
      )
    )

  unknown <- setdiff(
    c(distance$origin_code, distance$destination_code),
    zone$zone_code
  )
  if (length(unknown) > 0) {
    cli::cli_abort("Shipments have unknown zone code{?s} {.val {unknown}}.")
  }

  vctrs::vec_expand_grid(
    origin_code = zone$zone_code,
    destination_code = zone$zone_code
  ) |>
    tibble::as_tibble() |>
    dplyr::left_join(distance, by = c("origin_code", "destination_code")) |>
    dplyr::transmute(
      origin_code,
      destination_code,
      distance_great_circle = set_units_from(distance_great_circle, "mi", "km"),
      distance_routed = set_units_from(distance_routed, "mi", "km")
    )
}
