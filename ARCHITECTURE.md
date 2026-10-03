# Architecture

## Purpose

Ready-to-use US interregional freight flow data from the Commodity Flow Survey (CFS) Public Use File, for 2012, 2017, and 2022. Its main use is as ground-truth data for validating methods that estimate origin-destination flows.

Out of scope: subsampling and other noise simulation, transport costs, modeling, and redistributing data.

## Layout

- `inst/tarchives/<pipeline>/_targets.R`: one tarchives pipeline per survey year, `cfs-pumf-<year>` (PUMF, Public Use Microdata File, is the name of the 2012 file; 2017 calls it PUF and 2022 PUMS). Each declares the same targets with `tar_cfs_pumf()` and differs only in the URLs it downloads. The survey years are derived from these directories (`cfs_years()`), so adding a pipeline adds a year.
- `inst/tarchives/R/`: helpers shared by the pipelines. Following the naming of the other data packages, they are `read_file_<object>()` for parsing a downloaded file, `write_<object>()` for file targets, and `get_<object>()` for computed targets. `from_url()` downloads a file to a temporary path (`fs::file_temp()`), applies one of them, and deletes the file, so only the shipment Parquet file and the tables are kept in the store.
- `inst/tarchives/R/geography.R`: `geography_spec`, the zone levels (`"state"`, `"cfs_area"`) and how each one marks a suppressed origin. Everything that depends on the level (targets, flows, pairs, zones) is generated from it, so adding or refining a level means adding a row there, the `origin_<geography>_code` and `destination_<geography>_code` shipment columns, and a `get_county_zone_<geography>()` function that assigns counties to zones. `cfs_geographies` in `R/utils.R` must match it, which a test checks.
- `R/<object>-get.R` and `R/<object>-target.R`: getters and target factories (following econiodatajp), thin wrappers around `tarchives::tar_get_archive_raw()` and `tarchives::tar_target_archive_raw()` (through `cfs_get()` and `cfs_target()`). Target names are built by `cfs_name_archive()`.
- `tests/testthat/`: tests of the exported functions (`test-<object>-get.R`, `test-<object>-target.R`, mocking `cfs_get()`) and of the pipeline helpers (`test-tarchives-<name>.R`, which source `inst/tarchives/R/` in `helper.R`). Fixtures are small hand-written PUF files, the published data dictionaries, an excerpt of the county-to-CFS Area list, and square counties in the layout of the TIGER file (`fixtures/make-fixtures.R`).

- `README.qmd`: the source of `README.md`, rendered with `devtools::build_readme()`. Its examples run, so rendering builds the 2017 data unless it is cached.
- Tooling: air formats the code (`air.toml`, with editor settings in `.vscode/`), and GitHub Actions run R CMD check, test coverage, pkgdown, and the air format check (`.github/workflows/`, derived from the r-lib/actions and setup-air examples). The workflows pin actions to commit SHAs (kept up to date by Dependabot, `.github/dependabot.yml`), grant each job only the permissions it needs, check out without persisting credentials, cancel superseded runs on pull requests, and set timeouts. pkgdown deploys with GitHub Pages from Actions, so no job writes to the repository. Check the workflows with zizmor and actionlint after editing them. CI never builds the data: the tests use fixtures, and the examples that read data are wrapped in `\dontrun{}`. `DESCRIPTION` uses the `Config/roxygen2/` fields of roxygen2 8 and requires R 4.1 for `|>` and `\(x)`.

## Naming

- `cfs_<object>_get()`, for example `cfs_flow_get()`. CFS is the survey's official abbreviation.
- `cfs_<object>_target()` and `cfs_<object>_target_raw()` declare a target that reads the same data inside a targets pipeline, the first capturing the target name with non-standard evaluation and the second taking a string. `cfs_shipment_target()` is a file target of the Parquet path, because the records must not be loaded into memory.

## Output

Column naming, shared by freightdatajp and freightdataus:

- `_code` is a code from an official classification, `_id` is an arbitrary record identifier, and `_name` is a label.
- Both packages use the same column names. A column is omitted when the source has nothing to put in it.
- Words are spelled out (`longitude`, not `lon`). The one exception is counts, which are named `n_<things>` (for example `n_shipments`), following `n` from `dplyr::count()` and `n()`.
- Physical quantities are `units` columns, so names carry no unit suffix. Weight is in `t` (metric tonnes), distance in `km`, and time in `h`. Convert with `units::set_units()`, never by hand.
- Money stays numeric with the currency in the name (`value_usd`), because udunits has no currencies, and registering one with `units::install_unit()` would change the unit system of the user's whole session.

| Table | Getter | Keys | Values |
|---|---|---|---|
| Shipment | `cfs_shipment_get(year)` | `shipment_id` | `year` and the PUF variables, returned lazily |
| Flow | `cfs_flow_get(year, geography, by_mode)` | `year`, `commodity_code`, `origin_code`, `destination_code`, and `mode_code` if `by_mode = TRUE` | `commodity_name`, `mode_name` (if `by_mode = TRUE`), `weight`, `value_usd`, `n_shipments`, `n_records` |
| Zone | `cfs_zone_get(year, geography)` | `zone_code` | `zone_name`, `longitude`, `latitude` |
| Zone boundary | `cfs_zone_boundary_get(year, geography)` | `zone_code` | `zone_name`, `geometry` (an sf data frame) |
| Pair | `cfs_pair_get(year, geography)` | `origin_code`, `destination_code` | `distance_great_circle`, `distance_routed` |

- `geography` is `"state"` or `"cfs_area"`. `zone_code`, `origin_code`, and `destination_code` are the PUF codes for that level (`"06"` or `"06-348"`), stored as character.
- `commodity_code` is the SCTG code, and `mode_code` is the PUF mode code. Their `_name` columns come from the data dictionary of the users guide (Appendix A, published as a workbook).
  - The 2012 and 2017 workbooks lay out each appendix as a sheet with titles, notes, and sometimes several tables (the mode codes and the mode collapsing pattern in `"App A4"`). The pipeline gives the sheet of each code list (`sheet_commodity`, `sheet_mode`). The sheet is read cell by cell with tidyxl and split with `unpivotr::partition()`, following the strategy for several tables on one sheet in "Spreadsheet Munging Strategies": the corners are the header cell of the code list (`"SCTG"`, `"Mode Code"`) and the first cell of every block after an empty row, which ends the code list. The header is removed with `unpivotr::behead()`. Cell addresses are never written, and the build stops if the header is missing.
  - Codes of 10 and above are stored as numbers in these workbooks (for example `20`, `101`), and are converted to text.
  - Formatting is not used to find the tables: in 2017, the most detailed mode codes are bold, like the headers.
  - The tests read the sheets from each `_targets.R` and check them against the published workbooks in the fixtures.
  - The 2022 dictionary is a long table with one row per variable and value, so no sheet is needed.
- Weighted totals are the sum of `WGT_FACTOR` times the variable, as the CFS users guides specify.
  - `n_shipments` is the weighted number of shipments.
  - `n_records` is the unweighted number of records.
- The shipment table is lazy, so its columns are plain numbers in the PUF's units (pounds, US dollars, miles), as documented in roxygen. `units` columns are added only to tables that are returned in memory.
- The shipment table renames the PUF variables (for example `SHIPMT_WGHT` to `weight`, `WGT_FACTOR` to `weighting_factor`, and `TEMP_CNTL_YN` to the logical `temperature_controlled`). The mapping is `shipment_spec` in `inst/tarchives/R/shipment.R`.
- Records whose origin is suppressed at the requested level are left out (`geography_spec`): a suppressed origin state (`"00"`) at `geography = "state"`, and a suppressed origin CFS Area (metro area `"00000"`) at `geography = "cfs_area"`. Destinations are never suppressed.
- Collapsed codes are kept as published: SCTG groups (`"01-05"`), suppressed commodities (`"00"`), and collapsed or suppressed modes. The 2012 and 2017 dictionaries give no names for SCTG groups, so their `commodity_name` is `NA`; any other code without a name stops the build.
- Distances come only from the PUF. `distance_great_circle` and `distance_routed` of a pair are averages per shipment (the sum of `WGT_FACTOR` times the distance divided by the sum of `WGT_FACTOR`, as the users guides compute average miles per shipment), and `NA` for pairs without shipments. Pairs include every ordered pair of zones, including a zone with itself, whose distance is the actual distance of the shipments within the zone.
- Distances between representative points are not provided: every pair with a flow has a PUF distance, and the pairs without one (0.1 to 1.0% of the pairs) are exactly the pairs without flows.
- The representative point of a zone (`longitude`, `latitude`) is its center of population, not the geometric centroid or a principal city (which the remainders of states lack). It is defined the same way for every level, and it lies where people are.
  - County centers of population are only published for decennial censuses, so the census nearest to the survey year is used: 2010 for 2012, and 2020 for 2017 and 2022 (`url_county_population()`). The census year is derived from the survey year, never fixed.
  - The county centers (`CenPop<census>_Mean_CO.txt`) are assigned to zones with the county-to-CFS Area list (which has the county codes of every vintage), and aggregated with the Census Bureau formula: the latitude is the population-weighted mean, and the longitude is weighted by population times the cosine of the latitude. The source is "Centers of Population Computation for the United States 1950-2020" (US Census Bureau, 2021; <https://www2.census.gov/geo/pdfs/reference/cenpop2020/COP2020_documentation.pdf>), which applies the same formula to the nation, states, and counties. Aggregated to states, it matches the published state centers (`CenPop<census>_Mean_ST.txt`) within 5 m in every year.
  - The zones of the census must be those of the boundaries of the survey year, or the build stops. Zone names come from the boundaries.
  - Like any average, a center of population can fall outside its zone: in the hole of a remainder of a state that surrounds a metro area, or in water. This holds for 9 of the 132 CFS Areas of 2012 and 2017, and 10 of the 134 of 2022. Use the boundaries when a point inside the zone is needed.
  - The 2010 file is Latin-1 and the 2020 file UTF-8 with a byte order mark. Both are read as Latin-1 with columns named by position, since only ASCII columns are used.
  - `centr::mean_center()` was considered, but it uses a different definition and differs from the Census state centers by up to 18 km.
- Zone boundaries are `MULTIPOLYGON` geometries in WGS 84. sf stays in `Suggests`: `cfs_zone_boundary_get()` checks that it is installed.
- `longitude` and `latitude` are plain numbers in degrees (WGS 84).
- Data that change by year (boundaries, codes, names) are taken from the survey year, never fixed at one year.
- Missing variables are never filled in. The 2022 file has no routed distance, so `distance_routed` is `NA` for that year.

## Consistency across years

- Every year returns the same columns, with the same types and units. A variable that a year lacks is kept as an all-`NA` column, never dropped. In 2022 this applies to `distance_routed` and to quarter.
- In the shipment table, columns are the union over all years. For example, `naics_code` (2012 and 2017) and `sector_code` (2022) both exist, with `NA` where a year lacks them.
- CFS Area boundaries change between survey years, so the set of `zone_code` values differs by year. Document this, and do not map codes across years silently.
- Check that the commodity and mode code lists agree across years. If they do not, keep the published codes and document the difference. They do not:
  - Mode: 2012 and 2017 use the same codes (`"04"` is for-hire truck, with collapsed codes such as `"03"` truck and `"00"` suppressed), although some names differ (2012 "Private truck", 2017 "Company-owned truck"). 2022 uses a different list (`"111"` is for-hire truck, `"30"` unknown mode) and has no collapsed modes.
  - Commodity: 2012 also has `"99"` (missing code) and the group `"39-99"`, which 2017 renamed `"39-43"`. 2022 names its groups ("Aggregate of SCTG codes 01-05") and has no records with SCTG `"01"`.
  - Export destination: 2012 uses `"O"` (other) where 2017 and 2022 use `"A"`, `"E"`, and `"S"`.
- A test checks that every year's output has the same column names and types.

## Sources

Download the bulk CSV files. Do not use the Census API: it has no shipment records for 2022, and pulling every record through it would take many calls.

| Year | File |
|---|---|
| 2012 | `https://www2.census.gov/programs-surveys/cfs/datasets/2012/2012-pums-files/cfs-2012-pumf-csv.zip` |
| 2017 | `https://www2.census.gov/programs-surveys/cfs/datasets/2017/cfs-2017-puf-csv.zip` |
| 2022 | `https://www2.census.gov/programs-surveys/cfs/datasets/2022/cfs_2022_pums.zip` |

Users guides and data dictionaries are in the same directories.

| | 2012 | 2017 | 2022 |
|---|---|---|---|
| Records | 4,547,661 | 5,978,523 | 37,576,546 (a sample) |
| Routed distance | Yes | Yes | No |
| Quarter | Yes | Yes | No |
| Industry | `NAICS` | `NAICS` | `SECTOR` |
| Records with a suppressed origin CFS Area | 11,548 | 12,971 | 3,996 |
| CFS Areas | 132 | 132 | 134 |

The data dictionaries are `cfs-2012-pum-file-users-guide-app-a-jun2015.xlsx`, `cfs-2017-puf-users-guide-app-a-aug2020.xlsx`, and `cfs_2022_pums_data_dictionary.xlsx`. The 2012 workbook omits the Albany CFS Area (`"36-104"`), which the PDF users guide and the data have.

CFS Area geography is at <https://www.census.gov/programs-surveys/cfs/technical-documentation/geographies.html>. Build the polygons by dissolving the county boundaries of the survey year using the county-to-CFS Area list, so that every year is handled the same way:

- The counties are the TIGER/Line county and state layers in the CFS geography file of each survey year (`Shapefile of CFS Metro Areas for 2012 (requires ArcGIS to Open).zip`, the same for 2017, and `2022_CFS_Areas.zip`, in the directory above), read directly with sf. They are the boundaries that the CFS used: the 2022 file keeps the Connecticut counties, whereas the TIGER files of 2022 have planning regions. The CFS Area layers of these files are not used, because their format differs by year and their `INTPTLAT`/`INTPTLON` are those of one county, not of the CFS Area.
- tigris is not used: one file per year is needed, and downloading it like the other sources keeps the URL explicit and avoids tigris's cache and options.
- The county list is `list2022.xlsx`, which has the CFS Area of every county for 2007, 2012, 2017, and 2022 (`CFSyy_AREA`, `CFSyy_NAME`); the column of the survey year is used. CFS Area names come from it, because the 2012 dictionary is incomplete. State names come from the state layer.
- Counties of states that are not in the list (the territories) are left out.
- The list keeps both old and new codes of counties that changed. A county created after the list's assignment for the survey year (Petersburg Borough, Alaska, in the 2012 file) has no CFS Area in that year, and gets the only CFS Area of its state. The build stops if a state has more than one.

The tables were checked against the users guides. For 2012 and 2017, the record counts, values, and tons by mode, commodity, and origin state match Appendix B (PUF tabulations) to the dollar and ton. For 2022, the users guide has no Appendix B; the Maryland example matches in records (612,317) and in value to within $50 of $198.6 billion.

## Dependencies

- `duckplyr` (`Imports`):
  - reads the CSV files without loading them into memory, aggregates with dplyr verbs, and writes Parquet;
  - returns shipment records lazily.
  - Not arrow, which is much heavier. Not nanoparquet, which cannot aggregate data larger than memory.
- `units` (`Imports`): unit-aware columns and conversions.
- `rlang` (>= 1.2.0, `Imports`): argument checks (`check_bool()`, `check_number_whole()`, `check_string()`, and `arg_match()`, which rlang exports since 1.2.0, so the types-check standalone file is not needed).
- `stringr` (`Imports`), `targets` (`Imports`), `cli` (`Imports`).
- `Suggests`: packages used only inside the pipelines and tests (`curl`, `dplyr`, `fs`, `purrr`, `readxl`, `sf`, `tibble`, `vctrs`, `withr`).
- Style: fs for paths and files, stringr for strings (not `paste0()`, `sprintf()`, or `gsub()`), purrr for iteration (not `lapply()`), and vctrs and rlang where they fit (for example `vctrs::vec_expand_grid()` and `rlang::set_names()`).
- The shipment table is a Parquet file (a file target). Aggregated tables are small, so targets' default storage is used.
- Pipelines read the shipment data with `prudence = "stingy"`, so an operation that DuckDB cannot run fails instead of loading the table into memory. DuckDB column names are case-insensitive, so the PUF variables are prefixed before they are renamed.

## Roadmap (temporary)

Move this to GitHub issues once the repository is published.

1. ~~2017 shipment and flow tables.~~ Done: the totals by state, commodity, and mode match Appendix B of the 2017 users guide.
2. ~~2017 geography: polygons, centroids, and pair distances.~~ Done. The polygons are returned by `cfs_zone_boundary_get()`, and the representative points are centers of population.
3. ~~2012 and 2022.~~ Done.
