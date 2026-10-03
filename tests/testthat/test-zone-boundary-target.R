test_that("cfs_zone_boundary_target() declares a target that reads the boundaries", {
  target <- cfs_zone_boundary_target(
    zone_boundary,
    year = 2017,
    geography = "cfs_area"
  )

  expect_equal(target$settings$name, "zone_boundary")
  expect_match(target$command$string, "\"cfs-pumf-2017\"", fixed = TRUE)
  expect_match(
    target$command$string,
    "\"zone_boundary_cfs_area\"",
    fixed = TRUE
  )
})

test_that("cfs_zone_boundary_target_raw() checks its arguments", {
  expect_snapshot(error = TRUE, {
    cfs_zone_boundary_target_raw(
      "zone_boundary",
      year = 2017,
      geography = "county"
    )
  })
})
