test_that("write_shipment() converts a zipped PUF file to Parquet in the store", {
  file <- fs::path_abs(fixture_path("puf-2017.zip"))
  withr::local_dir(withr::local_tempdir())

  path <- write_shipment(file, year = 2017)

  expect_equal(path, as.character(path_user("shipment.parquet")))
  expect_equal(
    fs::path_file(fs::dir_ls(fs::path_dir(path))),
    "shipment.parquet"
  )
  shipment <- dplyr::collect(duckplyr::read_parquet_duckdb(path))
  expect_equal(nrow(shipment), 7)
  expect_named(shipment, c("year", shipment_spec$column))
})

test_that("clean_shipment() returns the same columns and types in every year", {
  types <- purrr::map(c(2012, 2017, 2022), function(year) {
    local_shipment(year) |>
      duckplyr::read_parquet_duckdb() |>
      dplyr::collect() |>
      col_types()
  })

  expect_named(types[[1]], c("year", shipment_spec$column))
  expect_equal(types[[2]], types[[1]])
  expect_equal(types[[3]], types[[1]])
})

test_that("clean_shipment() keeps codes and leaves missing variables NA", {
  shipment_2017 <- local_shipment(2017) |>
    duckplyr::read_parquet_duckdb() |>
    dplyr::collect()
  shipment_2022 <- local_shipment(2022) |>
    duckplyr::read_parquet_duckdb() |>
    dplyr::collect()

  expect_equal(shipment_2017$shipment_id[[1]], "0000001")
  expect_equal(shipment_2017$quarter[[1]], 4L)
  expect_equal(shipment_2017$commodity_code[[5]], "01-05")
  expect_equal(shipment_2017$origin_cfs_area_code[[6]], "00-00000")
  expect_equal(shipment_2017$temperature_controlled[2:3], c(FALSE, TRUE))
  expect_equal(shipment_2017$export_destination_code[[4]], "M")
  expect_all_equal(shipment_2017$sector_code, NA_character_)

  expect_equal(shipment_2022$sector_code[[1]], "31-33")
  expect_all_equal(shipment_2022$naics_code, NA_character_)
  expect_all_equal(shipment_2022$quarter, NA_integer_)
  expect_all_equal(shipment_2022$distance_routed, NA_real_)
})

test_that("read_csv_shipment() errors on unknown variables", {
  file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("SHIPMT_ID,NEW_VARIABLE", "0000001,1"), file)

  expect_snapshot(read_csv_shipment(file), error = TRUE)
})

test_that("read_shipment_zone() leaves out suppressed origins of every level", {
  shipment <- local_shipment(2017)

  state <- dplyr::collect(read_shipment_zone(shipment, "state"))
  cfs_area <- dplyr::collect(read_shipment_zone(shipment, "cfs_area"))

  expect_equal(nrow(state), 6)
  expect_equal(state$origin_code[[1]], "06")
  expect_equal(nrow(cfs_area), 5)
  expect_equal(cfs_area$destination_code[[1]], "06-348")
})
