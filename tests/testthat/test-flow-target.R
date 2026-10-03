test_that("cfs_flow_target() declares a target that reads the flows", {
  target <- cfs_flow_target(
    flow,
    year = 2017,
    geography = "cfs_area",
    by_mode = TRUE
  )

  expect_equal(target$settings$name, "flow")
  expect_match(target$command$string, "\"cfs-pumf-2017\"", fixed = TRUE)
  expect_match(target$command$string, "\"flow_cfs_area_mode\"", fixed = TRUE)
})

test_that("cfs_flow_target_raw() takes the name as a string", {
  target <- cfs_flow_target_raw("flow_2022", year = 2022)

  expect_equal(target$settings$name, "flow_2022")
  expect_match(target$command$string, "\"flow_state\"", fixed = TRUE)
})

test_that("cfs_flow_target_raw() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_flow_target_raw(1, year = 2017)
    cfs_flow_target_raw("flow", year = 2015)
    cfs_flow_target_raw("flow", year = 2017, geography = "county")
    cfs_flow_target_raw("flow", year = 2017, by_mode = NA)
  })
})
