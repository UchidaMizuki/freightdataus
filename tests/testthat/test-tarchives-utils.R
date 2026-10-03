test_that("url_census() percent-encodes each segment of the path", {
  expect_equal(
    url_census("programs-surveys/cfs/a file (2012).zip"),
    "https://www2.census.gov/programs-surveys/cfs/a%20file%20%282012%29.zip"
  )
})

test_that("from_url() applies a function to a temporary download", {
  path <- fs::path_abs(fixture_path("puf-2017.csv"))
  url <- stringr::str_c("file://", stringr::str_replace(path, "^(?!/)", "/"))

  file <- from_url(url, function(file) {
    expect_equal(readLines(file), readLines(path))
    file
  })

  expect_all_false(unname(fs::file_exists(file)))
})

test_that("path_user() returns an absolute path in the user directory of the store", {
  withr::local_dir(withr::local_tempdir())

  path <- path_user("file.zip")

  expect_match(path, "/_targets/user/file.zip$")
  expect_all_true(fs::is_absolute_path(path))
  expect_all_true(unname(fs::dir_exists(fs::path_dir(path))))
})

test_that("set_units_from() converts plain numbers", {
  expect_equal(
    set_units_from(2000, "lb", "t"),
    units::set_units(0.90718474, "t")
  )
})
