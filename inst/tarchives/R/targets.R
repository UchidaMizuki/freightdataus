# Targets of one survey year. Every year has the same targets, so the
# pipelines only differ in the files they download and, for dictionaries
# that reproduce Appendix A of the users guide, the sheets of the code lists
# (see `read_dictionary_table()`). Targets that depend on the zone
# level are declared for every level in `geography_spec`.
#
# Downloaded files are deleted once read (see `from_url()`), so only the
# shipment Parquet file and the tables are kept in the store.
tar_cfs_pumf <- function(
  year,
  url_shipment,
  url_dictionary,
  url_geography,
  sheet_commodity = NULL,
  sheet_mode = NULL
) {
  year <- as.integer(year)
  geographies <- geography_spec$geography

  county_zone <- purrr::map(geographies, function(geography) {
    targets::tar_target_raw(
      stringr::str_c("county_zone_", geography),
      rlang::call2(
        stringr::str_c("get_county_zone_", geography),
        quote(county),
        quote(county_cfs_area)
      )
    )
  })
  # The counties of the census, whose codes can differ from those of the
  # boundaries of the survey year.
  county_population_zone <- purrr::map(geographies, function(geography) {
    targets::tar_target_raw(
      stringr::str_c("county_population_zone_", geography),
      rlang::call2(
        stringr::str_c("get_county_zone_", geography),
        quote(county_population),
        quote(county_cfs_area)
      )
    )
  })
  zone <- purrr::map(geographies, function(geography) {
    targets::tar_target_raw(
      stringr::str_c("zone_", geography),
      rlang::expr(get_zone(
        !!rlang::sym(stringr::str_c("county_population_zone_", geography)),
        county_population = county_population,
        zone_boundary = !!rlang::sym(stringr::str_c(
          "zone_boundary_",
          geography
        ))
      ))
    )
  })
  zone_boundary <- purrr::map(geographies, function(geography) {
    targets::tar_target_raw(
      stringr::str_c("zone_boundary_", geography),
      rlang::expr(get_zone_boundary(
        county,
        county_zone = !!rlang::sym(stringr::str_c("county_zone_", geography))
      ))
    )
  })
  pair <- purrr::map(geographies, function(geography) {
    targets::tar_target_raw(
      stringr::str_c("pair_", geography),
      rlang::expr(get_pair(
        shipment,
        zone = !!rlang::sym(stringr::str_c("zone_", geography)),
        geography = !!geography
      ))
    )
  })
  flow <- vctrs::vec_expand_grid(
    geography = geographies,
    by_mode = c(FALSE, TRUE)
  ) |>
    purrr::pmap(function(geography, by_mode) {
      targets::tar_target_raw(
        stringr::str_c("flow_", geography, if (by_mode) "_mode"),
        rlang::expr(get_flow(
          shipment,
          year = !!year,
          geography = !!geography,
          by_mode = !!by_mode,
          dictionary_commodity = dictionary_commodity,
          dictionary_mode = dictionary_mode
        ))
      )
    })

  list(
    targets::tar_target_raw(
      "shipment",
      rlang::expr(from_url(!!url_shipment, write_shipment, year = !!year)),
      format = "file"
    ),
    targets::tar_target_raw(
      "dictionary_commodity",
      rlang::expr(from_url(
        !!url_dictionary,
        read_file_commodity,
        sheet = !!sheet_commodity
      ))
    ),
    targets::tar_target_raw(
      "dictionary_mode",
      rlang::expr(from_url(
        !!url_dictionary,
        read_file_mode,
        sheet = !!sheet_mode
      ))
    ),
    targets::tar_target_raw(
      "county",
      rlang::expr(from_url(!!url_geography, read_file_county))
    ),
    targets::tar_target_raw(
      "county_population",
      rlang::expr(from_url(
        !!url_county_population(year),
        read_file_county_population
      ))
    ),
    targets::tar_target_raw(
      "county_cfs_area",
      rlang::expr(from_url(
        !!url_census(path_county_cfs_area),
        read_file_county_cfs_area,
        year = !!year
      ))
    ),
    county_zone,
    county_population_zone,
    zone,
    zone_boundary,
    pair,
    flow
  )
}
