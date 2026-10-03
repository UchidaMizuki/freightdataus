test_that("get_pair() averages shipment distances for every pair of zones", {
  zone <- tibble::tibble(
    zone_code = c("06-348", "06-99999", "49-482"),
    zone_name = c("Los Angeles", "Remainder of California", "Salt Lake City"),
    longitude = c(-117.5, -118.5, -111.5),
    latitude = c(34.5, 35.5, 40.5)
  )

  pair <- get_pair(local_shipment(2017), zone, geography = "cfs_area")

  expect_s3_class(pair, "tbl_df")
  expect_named(
    pair,
    c(
      "origin_code",
      "destination_code",
      "distance_great_circle",
      "distance_routed"
    )
  )
  expect_equal(nrow(pair), 9)
  la_slc <- pair$origin_code == "06-348" & pair$destination_code == "49-482"
  expect_equal(
    pair$distance_great_circle[la_slc],
    set_units_from((1000 * 20 + 1100 * 10) / 30, "mi", "km")
  )
  expect_equal(
    pair$distance_routed[la_slc],
    set_units_from((1200 * 20 + 1300 * 10) / 30, "mi", "km")
  )
  expect_equal(
    as.numeric(pair$distance_great_circle[pair$origin_code == "49-482"]),
    c(NA, as.numeric(set_units_from(700, "mi", "km")), NA)
  )
})

test_that("get_pair() matches weighted.mean() with missing distances", {
  shipment <- local_shipment(2017) |>
    duckplyr::read_parquet_duckdb() |>
    dplyr::collect() |>
    dplyr::mutate(
      distance_routed = dplyr::if_else(
        shipment_id == "0000003",
        NA,
        distance_routed
      )
    )
  path <- withr::local_tempfile(fileext = ".parquet")
  duckplyr::as_duckdb_tibble(shipment) |>
    duckplyr::compute_parquet(path)
  zone <- tibble::tibble(zone_code = c("06", "49"), zone_name = c("CA", "UT"))

  pair <- get_pair(path, zone, geography = "state")

  ca_ut <- pair$origin_code == "06" & pair$destination_code == "49"
  expect_equal(
    pair$distance_routed[ca_ut],
    set_units_from(weighted.mean(c(1200, NA), c(20, 10)), "mi", "km")
  )
  expect_equal(
    pair$distance_great_circle[ca_ut],
    set_units_from(weighted.mean(c(1000, 1100), c(20, 10)), "mi", "km")
  )
})

test_that("get_pair() leaves the routed distance NA when the year lacks it", {
  zone <- tibble::tibble(
    zone_code = c("06", "49"),
    zone_name = c("California", "Utah"),
    longitude = c(-118, -111.5),
    latitude = c(35, 40.5)
  )

  pair <- get_pair(local_shipment(2022), zone, geography = "state")

  expect_all_true(is.na(pair$distance_routed))
  expect_s3_class(pair$distance_routed, "units")
})

test_that("get_pair() errors on shipments with unknown zones", {
  zone <- tibble::tibble(
    zone_code = "06",
    zone_name = "California",
    longitude = -118,
    latitude = 35
  )

  expect_snapshot(
    get_pair(local_shipment(2017), zone, geography = "state"),
    error = TRUE
  )
})
