# read_dictionary_table() errors when the sheet has no such code list

    Code
      read_file_mode(fixture_path("dictionary-2017.xlsx"), sheet = "App A3")
    Condition
      Error in `read_dictionary_table()`:
      ! Can't find the header "Mode Code" in sheet "App A3" of 'dictionary-2017.xlsx'.

# new_code_name() errors on duplicated codes

    Code
      new_code_name(tibble::tibble(code = c("01", "01"), name = c("a", "b")),
      "commodity")
    Condition
      Error in `new_code_name()`:
      ! The commodity code list is empty or has duplicated or missing values.

