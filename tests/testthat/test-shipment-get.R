test_that("cfs_shipment_get() returns the shipment records lazily", {
  path <- local_shipment(2017)
  local_mocked_bindings(cfs_get = function(year, name) {
    expect_equal(c(year, name), c("2017", "shipment"))
    path
  })

  shipment <- cfs_shipment_get(2017)

  expect_s3_class(shipment, "duckplyr_df")
  expect_equal(nrow(dplyr::collect(shipment)), 7)
})

test_that("cfs_shipment_get() checks its arguments", {
  expect_snapshot(cfs_shipment_get(2015), error = TRUE)
})
