

<!-- README.md is generated from README.qmd. Please edit that file -->

<!-- Rendering runs the examples, which build the 2017 data (about 230 MB of downloads) unless they are already cached. -->

# freightdataus

<!-- badges: start -->

[![R-CMD-check](https://github.com/UchidaMizuki/freightdataus/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/UchidaMizuki/freightdataus/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/UchidaMizuki/freightdataus/graph/badge.svg)](https://app.codecov.io/gh/UchidaMizuki/freightdataus)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

freightdataus provides ready-to-use US freight flow data from the
Commodity Flow Survey (CFS) Public Use File for 2012, 2017, and 2022. It
is meant as ground-truth data for validating methods that estimate
origin-destination flows.

The data are downloaded from the US Census Bureau and built the first
time you request them, using
[tarchives](https://github.com/UchidaMizuki/tarchives). Later requests
read the cached results.

## Installation

You can install the development version of freightdataus from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("UchidaMizuki/freightdataus")
```

## Usage

``` r
library(freightdataus)
```

Weighted flows between states or CFS Areas, by commodity and optionally
by mode:

``` r
cfs_flow_get(2017, geography = "cfs_area", by_mode = TRUE)
#> # A tibble: 479,578 × 11
#>     year commodity_code origin_code destination_code mode_code commodity_name 
#>    <int> <chr>          <chr>       <chr>            <chr>     <chr>          
#>  1  2017 00             02-99999    02-99999         00        SCTG suppressed
#>  2  2017 00             02-99999    30-99999         00        SCTG suppressed
#>  3  2017 00             02-99999    53-500           00        SCTG suppressed
#>  4  2017 00             02-99999    55-376           00        SCTG suppressed
#>  5  2017 00             05-99999    02-99999         00        SCTG suppressed
#>  6  2017 00             05-99999    05-99999         00        SCTG suppressed
#>  7  2017 00             05-99999    06-348           00        SCTG suppressed
#>  8  2017 00             05-99999    06-488           00        SCTG suppressed
#>  9  2017 00             05-99999    09-99999         00        SCTG suppressed
#> 10  2017 00             05-99999    12-99999         00        SCTG suppressed
#> # ℹ 479,568 more rows
#> # ℹ 5 more variables: mode_name <chr>, weight [t], value_usd <dbl>,
#> #   n_shipments <dbl>, n_records <int>
```

Zones with their centers of population, their boundaries (an sf data
frame), and the distances between zones:

``` r
cfs_zone_get(2017, geography = "cfs_area")
#> # A tibble: 132 × 4
#>    zone_code zone_name                                longitude latitude
#>    <chr>     <chr>                                        <dbl>    <dbl>
#>  1 01-142    Birmingham-Hoover-Talladega, AL CFS Area     -86.7     33.5
#>  2 01-380    Mobile-Daphne-Fairhope, AL CFS Area          -88.0     30.6
#>  3 01-99999  Remainder of Alabama                         -86.5     33.3
#>  4 02-99999  Remainder of Alaska                         -149.      61.4
#>  5 04-38060  Phoenix-Mesa-Scottsdale, AZ CFS Area        -112.      33.5
#>  6 04-536    Tucson-Nogales, AZ CFS Area                 -111.      32.2
#>  7 04-99999  Remainder of Arizona                        -112.      34.1
#>  8 05-99999  Remainder of Arkansas                        -92.7     35.2
#>  9 06-260    Fresno-Madera, CA CFS Area                  -120.      36.8
#> 10 06-348    Los Angeles-Long Beach, CA CFS Area         -118.      34.0
#> # ℹ 122 more rows
cfs_pair_get(2017, geography = "cfs_area")
#> # A tibble: 17,424 × 4
#>    origin_code destination_code distance_great_circle distance_routed
#>    <chr>       <chr>                             [km]            [km]
#>  1 01-142      01-142                            21.5            27.4
#>  2 01-142      01-380                           322.            402. 
#>  3 01-142      01-99999                         122.            147. 
#>  4 01-142      02-99999                        5272.           5658. 
#>  5 01-142      04-38060                        2351.           2692. 
#>  6 01-142      04-536                          2261.           2581. 
#>  7 01-142      04-99999                        2357.           2688. 
#>  8 01-142      05-99999                         566.            700. 
#>  9 01-142      06-260                          3025.           3701. 
#> 10 01-142      06-348                          2888.           3283. 
#> # ℹ 17,414 more rows
```

``` r
cfs_zone_boundary_get(2017, geography = "cfs_area")
```

Shipment records, returned lazily as a duckplyr frame, to tabulate them
in other ways:

``` r
cfs_shipment_get(2017) |>
  dplyr::summarise(
    value_usd = sum(weighting_factor * value_usd),
    .by = mode_code
  ) |>
  dplyr::arrange(mode_code) |>
  dplyr::collect()
#> # A tibble: 21 × 2
#>    mode_code value_usd
#>  * <chr>         <dbl>
#>  1 00          6.44e 9
#>  2 02          1.61e11
#>  3 03          7.46e 8
#>  4 04          6.96e12
#>  5 05          3.43e12
#>  6 06          2.20e11
#>  7 07          1.94e10
#>  8 08          8.99e10
#>  9 09          2.69e 8
#> 10 10          5.76e10
#> # ℹ 11 more rows
```

Inside a [targets](https://docs.ropensci.org/targets/) pipeline, declare
targets that read the data:

``` r
# _targets.R
library(targets)

list(
  freightdataus::cfs_flow_target(flow, year = 2017, geography = "cfs_area"),
  freightdataus::cfs_pair_target(pair, year = 2017, geography = "cfs_area")
)
```

Every year returns the same columns, with the same types and units.
Weights are in metric tonnes and distances in km (`units` columns), and
values are in US dollars. Weighted totals are the sum of the weighting
factor times the variable, as the CFS users guides specify.

Codes are kept as published, and some of them differ between years. In
particular, the mode codes of 2022 are not those of 2012 and 2017, and
CFS Area boundaries change between survey years.
