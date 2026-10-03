# Code lists from the data dictionaries in the users guides. The 2012 and 2017
# dictionaries are workbooks that reproduce Appendix A of the users guide, one
# sheet per appendix, so the pipeline gives the sheet of each code list. The
# 2022 dictionary is a single long table with one row per variable and value,
# so `sheet` is `NULL` for it.

read_file_commodity <- function(file, sheet = NULL) {
  if (is.null(sheet)) {
    data <- read_dictionary_variable(file, "SCTG")
  } else {
    data <- read_dictionary_table(file, sheet, header = "SCTG")
  }
  new_code_name(data, "commodity")
}

read_file_mode <- function(file, sheet = NULL) {
  if (is.null(sheet)) {
    data <- read_dictionary_variable(file, "MODE")
  } else {
    data <- read_dictionary_table(file, sheet, header = "Mode Code")
  }
  new_code_name(data, "mode")
}

# An appendix sheet can hold several tables, with titles and notes, such as
# the mode codes and the mode collapsing pattern in "App A4". Following the
# strategy for several tables on one sheet in "Spreadsheet Munging
# Strategies" (Garmonsway), the sheet is partitioned at corner cells: the
# header cell of the code list (whose text is `header`), and the first cell
# of every block that follows an empty row, which ends the code list. The
# code list is the partition of the header, with the codes in its first
# column and the names in its second.
read_dictionary_table <- function(file, sheet, header) {
  cells <- tidyxl::xlsx_cells(file, sheets = sheet) |>
    dplyr::filter(!is_blank)
  rows <- unique(cells$row)
  corners <- cells |>
    dplyr::filter(col == 1, character %in% header | !(row - 1L) %in% rows)
  corner <- dplyr::filter(corners, character %in% header)
  if (nrow(corner) != 1) {
    cli::cli_abort(
      "Can't find the header {.val {header}} in sheet {.val {sheet}} of {.file {fs::path_file(file)}}."
    )
  }

  partitions <- unpivotr::partition(cells, corners)
  partitions$cells[[which(partitions$corner_row == corner$row)]] |>
    unpivotr::behead("up", heading) |>
    dplyr::filter(col %in% 1:2) |>
    dplyr::transmute(
      row,
      col,
      # Codes of 10 and above are stored as numbers.
      value = dplyr::coalesce(character, as.character(numeric))
    ) |>
    tidyr::pivot_wider(names_from = col, values_from = value) |>
    dplyr::select(code = "1", name = "2")
}

read_dictionary_variable <- function(file, variable) {
  readxl::read_excel(file, sheet = 1, col_types = "text") |>
    dplyr::filter(VARIABLE == variable) |>
    dplyr::select(code = VALUE_CODE, name = VALUE_LABEL)
}

new_code_name <- function(data, object) {
  data <- dplyr::mutate(
    data,
    dplyr::across(c(code, name), stringr::str_squish)
  )
  if (nrow(data) == 0 || vctrs::vec_duplicate_any(data$code) || anyNA(data)) {
    cli::cli_abort(
      "The {object} code list is empty or has duplicated or missing values."
    )
  }
  rlang::set_names(data, stringr::str_c(object, c("_code", "_name")))
}
