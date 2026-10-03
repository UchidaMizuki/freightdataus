test_that("cfs_flow_get() reads the target of the year, geography, and mode", {
  local_mocked_bindings(cfs_get = function(year, name) {
    stringr::str_c(year, " ", name)
  })

  expect_equal(cfs_flow_get(2017), "2017 flow_state")
  expect_equal(
    cfs_flow_get(2022, geography = "cfs_area", by_mode = TRUE),
    "2022 flow_cfs_area_mode"
  )
})

test_that("cfs_flow_get() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_flow_get(2015)
    cfs_flow_get("2017")
    cfs_flow_get(2017, geography = "county")
    cfs_flow_get(2017, by_mode = NA)
  })
})
