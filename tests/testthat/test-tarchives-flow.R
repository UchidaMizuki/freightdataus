test_that("get_flow() sums weighted shipments by commodity, origin, and destination", {
  flow <- get_flow(
    local_shipment(2017),
    year = 2017,
    geography = "state",
    by_mode = FALSE,
    dictionary_commodity = fixture_dictionary(2017, "commodity"),
    dictionary_mode = fixture_dictionary(2017, "mode")
  )

  expect_named(
    flow,
    c(
      "year",
      "commodity_code",
      "origin_code",
      "destination_code",
      "commodity_name",
      "weight",
      "value_usd",
      "n_shipments",
      "n_records"
    )
  )
  expect_equal(flow$commodity_code, c("01-05", "34", "43", "43", "43"))
  expect_equal(flow$origin_code, c("06", "06", "06", "06", "49"))
  expect_equal(flow$destination_code, c("06", "06", "06", "49", "06"))
  expect_equal(flow$commodity_name[[1]], NA_character_)
  expect_equal(flow$value_usd, c(1200, 625, 40000, 2500, 200))
  expect_equal(
    flow$weight,
    set_units_from(c(8000, 1100, 4000, 140, 20), "lb", "t")
  )
  expect_equal(flow$n_shipments, c(4, 2.5, 10, 30, 2))
  expect_equal(flow$n_records, c(1L, 1L, 1L, 2L, 1L))
})

test_that("get_flow() tabulates by mode and leaves out suppressed CFS Areas", {
  flow <- get_flow(
    local_shipment(2017),
    year = 2017,
    geography = "cfs_area",
    by_mode = TRUE,
    dictionary_commodity = fixture_dictionary(2017, "commodity"),
    dictionary_mode = fixture_dictionary(2017, "mode")
  )

  expect_equal(flow$origin_code, c("06-348", "06-348", "06-99999", "49-482"))
  expect_equal(flow$mode_code, c("04", "14", "05", "04"))
  expect_equal(flow$mode_name[[1]], "For-hire truck")
  expect_equal(sum(flow$n_records), 5L)
})

test_that("get_flow() returns the same columns and types in every year", {
  types <- purrr::map(c(2012, 2017, 2022), function(year) {
    get_flow(
      local_shipment(year),
      year = year,
      geography = "cfs_area",
      by_mode = TRUE,
      dictionary_commodity = fixture_dictionary(year, "commodity"),
      dictionary_mode = fixture_dictionary(year, "mode")
    ) |>
      col_types()
  })

  expect_equal(types[[2]], types[[1]])
  expect_equal(types[[3]], types[[1]])
})

test_that("join_code_name() errors on codes without a name", {
  data <- tibble::tibble(mode_code = c("04", "99"))
  dictionary <- tibble::tibble(mode_code = "04", mode_name = "For-hire truck")

  expect_snapshot(join_code_name(data, dictionary, "mode"), error = TRUE)
})
