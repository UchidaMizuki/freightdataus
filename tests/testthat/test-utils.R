test_that("cfs_years() lists the years of the bundled pipelines", {
  expect_equal(cfs_years(), c(2012L, 2017L, 2022L))
})

test_that("cfs_geographies matches the levels of the pipelines", {
  expect_equal(cfs_geographies, geography_spec$geography)
})

test_that("cfs_name_archive() names the targets of the pipelines", {
  expect_equal(cfs_name_archive("shipment"), "shipment")
  expect_equal(cfs_name_archive("zone", "state"), "zone_state")
  expect_equal(cfs_name_archive("flow", "cfs_area", TRUE), "flow_cfs_area_mode")
})

test_that("check_year() accepts the survey years", {
  expect_no_error(check_year(2012))
  expect_no_error(check_year(2017L))
  expect_no_error(check_year(2022))
})
