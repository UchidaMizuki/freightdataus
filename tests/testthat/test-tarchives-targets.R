test_that("tar_cfs_pumf() declares the same targets for every year and level", {
  targets <- tar_cfs_pumf(
    2017,
    "shipment.zip",
    "dictionary.xlsx",
    "geography.zip"
  ) |>
    purrr::list_flatten()
  names <- purrr::map_chr(targets, \(x) x$settings$name)

  expect_setequal(
    names,
    c(
      "shipment",
      "dictionary_commodity",
      "dictionary_mode",
      "county",
      "county_cfs_area",
      "county_population",
      stringr::str_c("county_zone_", geography_spec$geography),
      stringr::str_c("county_population_zone_", geography_spec$geography),
      stringr::str_c("zone_", geography_spec$geography),
      stringr::str_c("zone_boundary_", geography_spec$geography),
      stringr::str_c("pair_", geography_spec$geography),
      stringr::str_c("flow_", geography_spec$geography),
      stringr::str_c("flow_", geography_spec$geography, "_mode")
    )
  )
})
