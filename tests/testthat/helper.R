# Functions of the pipelines, which live in inst/tarchives/R.
env <- rlang::current_env()
fs::dir_ls(system.file("tarchives", "R", package = "freightdataus")) |>
  purrr::walk(\(file) source(file, local = env))
rm(env)

fixture_path <- function(...) {
  test_path("fixtures", ...)
}

# The shipment target of a fixture PUF file.
local_shipment <- function(year, env = rlang::caller_env()) {
  path <- withr::local_tempfile(fileext = ".parquet", .local_envir = env)
  read_csv_shipment(fixture_path(stringr::str_c("puf-", year, ".csv"))) |>
    clean_shipment(year = year) |>
    duckplyr::compute_parquet(path)
  path
}

# The sheet of a code list, as declared in the _targets.R of the
# pipeline of `year` (`NULL` for 2022), so that tests check the sheets that
# the pipelines use against the published dictionaries.
pipeline_sheet <- function(year, object) {
  script <- system.file(
    "tarchives",
    stringr::str_c("cfs-pumf-", year),
    "_targets.R",
    package = "freightdataus"
  )
  call <- purrr::detect(parse(script), \(x) rlang::is_call(x, "tar_cfs_pumf"))
  rlang::call_args(call)[[stringr::str_c("sheet_", object)]]
}

# A code list of the published dictionary of `year`, read as the pipeline
# reads it.
fixture_dictionary <- function(year, object) {
  rlang::exec(
    stringr::str_c("read_file_", object),
    fixture_path(stringr::str_c("dictionary-", year, ".xlsx")),
    sheet = pipeline_sheet(year, object)
  )
}

fixture_county <- function() {
  read_file_county(fixture_path("geography.zip"))
}

fixture_county_population <- function() {
  read_file_county_population(fixture_path("county-population.txt"))
}

fixture_county_cfs_area <- function(year) {
  read_file_county_cfs_area(fixture_path("county-cfs-area.xlsx"), year = year)
}

col_types <- function(data) {
  purrr::map_chr(data, \(x) class(x)[[1]])
}
