test_that("cfs_pair_get() reads the target of the year and geography", {
  local_mocked_bindings(cfs_get = function(year, name) {
    stringr::str_c(year, " ", name)
  })

  expect_equal(cfs_pair_get(2022), "2022 pair_state")
  expect_equal(cfs_pair_get(2012, "cfs_area"), "2012 pair_cfs_area")
})

test_that("cfs_pair_get() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_pair_get(c(2012, 2017))
    cfs_pair_get(2017, geography = "county")
  })
})
