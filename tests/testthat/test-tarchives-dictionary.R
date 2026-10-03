test_that("read_file_commodity() reads the SCTG codes of every year", {
  commodity_2012 <- fixture_dictionary(2012, "commodity")
  commodity_2017 <- fixture_dictionary(2017, "commodity")
  commodity_2022 <- fixture_dictionary(2022, "commodity")

  expect_named(commodity_2017, c("commodity_code", "commodity_name"))
  expect_equal(nrow(commodity_2012), 44)
  expect_equal(nrow(commodity_2017), 43)
  expect_equal(commodity_2012$commodity_code[c(1, 44)], c("01", "00"))
  expect_equal(commodity_2017$commodity_code[c(1, 43)], c("01", "00"))
  expect_equal(
    commodity_2017$commodity_name[commodity_2017$commodity_code == "01"],
    "Animals and Fish (live)"
  )
  expect_contains(commodity_2012$commodity_code, "99")
  expect_equal(
    commodity_2022$commodity_name[commodity_2022$commodity_code == "01-05"],
    "Aggregate of SCTG codes 01-05"
  )
})

test_that("read_file_mode() reads the mode codes of every year", {
  mode_2012 <- fixture_dictionary(2012, "mode")
  mode_2017 <- fixture_dictionary(2017, "mode")
  mode_2022 <- fixture_dictionary(2022, "mode")

  expect_named(mode_2017, c("mode_code", "mode_name"))
  expect_equal(nrow(mode_2012), 21)
  expect_equal(nrow(mode_2017), 21)
  expect_equal(nrow(mode_2022), 16)
  expect_equal(mode_2017$mode_code[c(1, 21)], c("02", "00"))
  expect_equal(
    mode_2012$mode_name[mode_2012$mode_code == "05"],
    "Private truck"
  )
  expect_equal(
    mode_2017$mode_name[mode_2017$mode_code == "05"],
    "Company-owned truck"
  )
  expect_equal(
    mode_2022$mode_name[mode_2022$mode_code == "111"],
    "For-hire truck"
  )
})

test_that("read_dictionary_table() ends the code list at the next block", {
  file <- fixture_path("dictionary-2017.xlsx")

  # The mode codes are followed by the mode collapsing pattern, and the
  # commodity codes by a note.
  mode <- read_dictionary_table(file, "App A4", header = "Mode Code")
  commodity <- read_dictionary_table(file, "App A3", header = "SCTG")

  expect_equal(mode$code[c(1, nrow(mode))], c("02", "00"))
  expect_equal(commodity$code[c(1, nrow(commodity))], c("01", "00"))
  expect_contains(mode$code, "101")
})

test_that("read_dictionary_table() errors when the sheet has no such code list", {
  expect_snapshot(
    read_file_mode(fixture_path("dictionary-2017.xlsx"), sheet = "App A3"),
    error = TRUE
  )
})

test_that("new_code_name() errors on duplicated codes", {
  expect_snapshot(
    new_code_name(
      tibble::tibble(code = c("01", "01"), name = c("a", "b")),
      "commodity"
    ),
    error = TRUE
  )
})
