# URL of a file on the Census Bureau's file server, from its path as shown in
# the directory listings, such as "programs-surveys/cfs/.../Shapefile of CFS
# Metro Areas for 2012 (requires ArcGIS to Open).zip". Each path segment is
# percent-encoded, so paths can be written as they read.
url_census <- function(path) {
  path <- stringr::str_split_1(path, "/") |>
    purrr::map_chr(curl::curl_escape) |>
    stringr::str_flatten("/")
  stringr::str_c("https://www2.census.gov/", path)
}

# Apply `f` to the file at `url`, downloaded to a temporary file that is
# deleted afterwards, so that only the results are kept in the store.
from_url <- function(url, f, ...) {
  file <- fs::file_temp(ext = fs::path_ext(url))
  withr::defer(fs::file_delete(file))
  curl::curl_download(url, file, quiet = TRUE)
  f(file, ...)
}

# Path to a file in the user directory of the store, which is created if
# needed. The getters read file targets from a different working directory,
# so the path must be absolute.
path_user <- function(file) {
  dir <- fs::dir_create(fs::path(targets::tar_path_store(), "user"))
  fs::path_abs(fs::path(dir, file))
}

set_units_from <- function(x, from, to) {
  x <- units::set_units(x, from, mode = "standard")
  units::set_units(x, to, mode = "standard")
}
