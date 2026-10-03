test_that("read_file_county() reads the counties and states of the geography file", {
  county <- fixture_county()

  expect_s3_class(county, "sf")
  expect_named(county, c("state_code", "state_name", "county_code", "geometry"))
  expect_equal(sf::st_crs(county), sf::st_crs(4326))
  expect_equal(county$state_name[county$county_code == "06037"], "California")
})

test_that("read_file_county_cfs_area() reads the CFS Areas of the year", {
  county_cfs_area <- fixture_county_cfs_area(2017)

  expect_equal(
    county_cfs_area$county_code,
    c("02020", "02063", "06029", "06037", "49035")
  )
  expect_equal(
    county_cfs_area$cfs_area_code,
    c("02-99999", NA, "06-99999", "06-348", "49-482")
  )
  expect_equal(
    county_cfs_area$cfs_area_name[[4]],
    "Los Angeles-Long Beach, CA CFS Area"
  )
})

test_that("get_county_zone_state() assigns the counties of the CFS to states", {
  county_zone <- get_county_zone_state(
    fixture_county(),
    fixture_county_cfs_area(2017)
  )

  expect_named(county_zone, c("county_code", "zone_code", "zone_name"))
  expect_equal(county_zone$zone_code, c("02", "02", "06", "06", "49"))
})

test_that("get_county_zone_cfs_area() assigns a new county the only CFS Area of its state", {
  county_cfs_area <- fixture_county_cfs_area(2017)

  county_zone <- get_county_zone_cfs_area(fixture_county(), county_cfs_area)

  expect_named(county_zone, c("county_code", "zone_code", "zone_name"))
  expect_equal(
    county_zone$zone_code,
    c("02-99999", "02-99999", "06-99999", "06-348", "49-482")
  )
  expect_equal(county_zone$zone_name[[2]], "Remainder of Alaska")

  county_cfs_area$cfs_area_code[[5]] <- NA
  expect_snapshot(
    get_county_zone_cfs_area(fixture_county(), county_cfs_area),
    error = TRUE
  )
})

test_that("get_zone_boundary() dissolves the counties of each zone", {
  county <- fixture_county()
  county_zone <- get_county_zone_cfs_area(county, fixture_county_cfs_area(2017))

  zone_boundary <- get_zone_boundary(county, county_zone)

  expect_s3_class(zone_boundary, "sf")
  expect_named(zone_boundary, c("zone_code", "zone_name", "geometry"))
  expect_equal(
    zone_boundary$zone_code,
    c("02-99999", "06-348", "06-99999", "49-482")
  )
  expect_all_equal(
    as.character(sf::st_geometry_type(zone_boundary)),
    "MULTIPOLYGON"
  )
})

test_that("url_county_population() takes the census nearest to the survey year", {
  expect_match(url_county_population(2012), "/cenpop2010/county/CenPop2010_")
  expect_match(url_county_population(2017), "/cenpop2020/county/CenPop2020_")
  expect_match(url_county_population(2022), "/cenpop2020/county/CenPop2020_")
})

test_that("read_file_county_population() reads the county centers of population", {
  county_population <- fixture_county_population()

  expect_named(
    county_population,
    c(
      "state_code",
      "state_name",
      "county_code",
      "population",
      "longitude",
      "latitude"
    )
  )
  expect_equal(county_population$county_code[[1]], "02020")
  expect_equal(county_population$state_name[[1]], "Alaska")
  expect_equal(county_population$population[[1]], 291247)
  expect_equal(county_population$longitude[[1]], -149.792287)
  expect_equal(county_population$latitude[[1]], 61.191547)
})

test_that("read_file_county_population() reads the Latin-1 file of 2010", {
  file <- withr::local_tempfile(fileext = ".txt")
  con <- file(file, "wb")
  writeLines(
    "STATEFP,COUNTYFP,COUNAME,STNAME,POPULATION,LATITUDE,LONGITUDE",
    con,
    sep = "\n"
  )
  # "Doña Ana" in Latin-1.
  writeBin(
    c(
      charToRaw("35,013,Do"),
      as.raw(0xF1),
      charToRaw("a Ana,New Mexico,209233,+32.2,-106.8\n")
    ),
    con
  )
  close(con)

  county_population <- read_file_county_population(file)

  expect_equal(county_population$county_code, "35013")
  expect_equal(county_population$population, 209233)
  expect_equal(county_population$latitude, 32.2)
})

test_that("get_zone() returns the centers of population of the zones", {
  county <- fixture_county()
  county_population <- fixture_county_population()
  county_cfs_area <- fixture_county_cfs_area(2017)

  zone <- get_zone(
    get_county_zone_cfs_area(county_population, county_cfs_area),
    county_population = county_population,
    zone_boundary = get_zone_boundary(
      county,
      get_county_zone_cfs_area(county, county_cfs_area)
    )
  )

  expect_s3_class(zone, "tbl_df")
  expect_named(zone, c("zone_code", "zone_name", "longitude", "latitude"))
  expect_equal(zone$zone_code, c("02-99999", "06-348", "06-99999", "49-482"))
  expect_equal(zone$zone_name[[1]], "Remainder of Alaska")
  population <- c(291247, 7102)
  latitude <- c(61.191547, 60.881369)
  longitude <- c(-149.792287, -146.199156)
  weight_longitude <- population * cos(latitude * pi / 180)
  expect_equal(zone$latitude[[1]], sum(population * latitude) / sum(population))
  expect_equal(
    zone$longitude[[1]],
    sum(weight_longitude * longitude) / sum(weight_longitude)
  )
  expect_equal(zone$longitude[[2]], -118.245990)
})

test_that("get_zone() errors when the zones differ from the boundaries", {
  county <- fixture_county()
  county_population <- fixture_county_population()
  zone_boundary <- get_zone_boundary(
    county,
    get_county_zone_state(county, fixture_county_cfs_area(2017))
  )

  expect_snapshot(
    get_zone(
      get_county_zone_state(
        county_population[-5, ],
        fixture_county_cfs_area(2017)
      ),
      county_population = county_population,
      zone_boundary = zone_boundary
    ),
    error = TRUE
  )
})

test_that("get_zone() and get_zone_boundary() return the same columns and types in every year and level", {
  county <- fixture_county()
  county_population <- fixture_county_population()
  types <- vctrs::vec_expand_grid(
    year = c(2012, 2017, 2022),
    geography = geography_spec$geography
  ) |>
    purrr::pmap(function(year, geography) {
      get_county_zone <- stringr::str_c("get_county_zone_", geography)
      county_cfs_area <- fixture_county_cfs_area(year)
      zone_boundary <- get_zone_boundary(
        county,
        rlang::exec(get_county_zone, county, county_cfs_area)
      )
      zone <- get_zone(
        rlang::exec(get_county_zone, county_population, county_cfs_area),
        county_population = county_population,
        zone_boundary = zone_boundary
      )
      list(zone = col_types(zone), zone_boundary = col_types(zone_boundary))
    })

  expect_equal(vctrs::vec_unique_count(types), 1L)
})
