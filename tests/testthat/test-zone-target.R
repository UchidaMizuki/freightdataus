test_that("cfs_zone_target() declares a target that reads the zones", {
  target <- cfs_zone_target(zone, year = 2012, geography = "cfs_area")

  expect_equal(target$settings$name, "zone")
  expect_match(target$command$string, "\"cfs-pumf-2012\"", fixed = TRUE)
  expect_match(target$command$string, "\"zone_cfs_area\"", fixed = TRUE)
})

test_that("cfs_zone_target_raw() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_zone_target_raw("zone", year = 2020)
    cfs_zone_target_raw("zone", year = 2017, geography = "county")
  })
})
