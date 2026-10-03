test_that("cfs_zone_get() reads the target of the year and geography", {
  local_mocked_bindings(cfs_get = function(year, name) {
    stringr::str_c(year, " ", name)
  })

  expect_equal(cfs_zone_get(2012), "2012 zone_state")
  expect_equal(cfs_zone_get(2017, "cfs_area"), "2017 zone_cfs_area")
})

test_that("cfs_zone_get() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_zone_get(2020)
    cfs_zone_get(2017, geography = "county")
  })
})
