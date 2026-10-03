test_that("cfs_pair_target() declares a target that reads the pairs", {
  target <- cfs_pair_target(pair, year = 2022)

  expect_equal(target$settings$name, "pair")
  expect_match(target$command$string, "\"cfs-pumf-2022\"", fixed = TRUE)
  expect_match(target$command$string, "\"pair_state\"", fixed = TRUE)
})

test_that("cfs_pair_target_raw() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_pair_target_raw("pair", year = 2017, geography = "county")
  })
})
