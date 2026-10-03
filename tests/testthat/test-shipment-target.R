test_that("cfs_shipment_target() declares a file target of the shipment records", {
  target <- cfs_shipment_target(shipment, year = 2017)

  expect_equal(target$settings$name, "shipment")
  expect_equal(target$settings$format, "file")
  expect_match(target$command$string, "\"cfs-pumf-2017\"", fixed = TRUE)
  expect_match(target$command$string, "\"shipment\"", fixed = TRUE)
})

test_that("cfs_shipment_target_raw() checks its arguments", {
  expect_snapshot(
    cfs_shipment_target_raw("shipment", year = 2015),
    error = TRUE
  )
})
