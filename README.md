verisr2
=======

Convenience functions for exploratory analysis on VERIS database
(<a href="http://veriscommunity.net" class="uri">http://veriscommunity.net</a>).

Small helper functions for working with the data frame objects from the
[VERIS Community Database (VCDB)](http://veriscommunity.net/vcdb.html),
typically converted from JSON using the
[verisr](https://github.com/vz-risk/verisr) package (or, if unavailable,
from this my fork of [this
package](https://github.com/onlyphantom/verisr)). This package
replicates in base R or dplyr many of the helper functions originally
implemented in the verisr package by Jay Jacobs.

The original package by Jay uses `data.table` code that is deprecated
and no longer works with recent versions of R. The author has stated his
desire to one day rewrite these functions in dplyr code but since effort
on that has been stagnant for a few years now this is a simple attempt
to recreate these helper functions in `dplyr` or base R code.

Installation and Getting Started
--------------------------------

Install it from github and load the built-in dataset:

``` r
# install devtools from https://github.com/hadley/devtools
devtools::install_github("onlyphantom/verisr2")
library(verisr2)
data(vcdb)
```

Inspecting the class of the data:

``` r
class(vcdb)
```

    ## [1] "verisr"     "data.frame"

Because the incidents are originally recorded in JSON, the transformed
data is “wide” spanning across more than 2,430 variables as of this
writing. The VERIS specification has intended for the data schema to be
extended upon, and when expressed as a data frame, this wide format
presents an opportunity for data analysis and exploratory exercises:

``` r
dim(vcdb)
```

    ## [1] 8198 2436

Convenience Functions
---------------------

Retrieve a list of variables (enumeration / factors) in the data frame
from a specified “parent”:

``` r
getenum_stri(vcdb, "action.error.vector")[1:5]
```

    ## [1] "action.error.vector.Carelessness"         
    ## [2] "action.error.vector.Inadequate personnel" 
    ## [3] "action.error.vector.Inadequate processes" 
    ## [4] "action.error.vector.Inadequate technology"
    ## [5] "action.error.vector.Other"

The same function can also be performed with a vector of (character)
strings instead of a single string value:

``` r
getenum_stri(vcdb, c("actor.internal.motive", "value_chain.money laundering.variety"))[8:12]
```

    ## [1] "actor.internal.motive.NA"                 
    ## [2] "actor.internal.motive.Other"              
    ## [3] "actor.internal.motive.Secondary"          
    ## [4] "actor.internal.motive.Unknown"            
    ## [5] "value_chain.money laundering.variety.Bank"

To get a frequency table, use `getenum_tbl`:

``` r
getenum_tbl(vcdb, c("action", "asset.variety"))
```

    ##           action.Malware           action.Hacking            action.Social 
    ##                      678                     2185                      554 
    ##          action.Physical            action.Misuse             action.Error 
    ##                     1565                     1675                     2374 
    ##     action.Environmental           action.Unknown     asset.variety.Server 
    ##                        8                      237                     3819 
    ##    asset.variety.Network   asset.variety.User Dev      asset.variety.Media 
    ##                      157                     1478                     2207 
    ##     asset.variety.Person asset.variety.Kiosk/Term    asset.variety.Unknown 
    ##                      606                      345                      646 
    ##   asset.variety.Embedded 
    ##                        2

We can use `getenum_df` function to get both the count and the
proportion of assets where data loss has occured. This replicates the
original functionality from `jayjacobs` and `vz-risk`’s version but uses
base R in its underlying function:

``` r
getenum_df(vcdb, "asset.variety")
```

    ##         enum    x    n    freq
    ## 1     Server 3819 8188 0.46641
    ## 2      Media 2207 8188 0.26954
    ## 3   User Dev 1478 8188 0.18051
    ## 4     Person  606 8188 0.07401
    ## 5 Kiosk/Term  345 8188 0.04213
    ## 6    Network  157 8188 0.01917
    ## 7   Embedded    2 8188 0.00024
    ## 8    Unknown  646   NA      NA

Similarly, we can pass in a vector of two characters to the function,
which will count the number of incidents across the two enumerations:

``` r
getenum_df(vcdb, c("action", "asset.variety"))
```

    ## # A tibble: 64 x 3
    ##    action   asset.variety     x
    ##    <chr>    <chr>         <int>
    ##  1 Hacking  Server         1890
    ##  2 Error    Media          1395
    ##  3 Misuse   Server         1030
    ##  4 Physical User Dev        706
    ##  5 Error    Server          662
    ##  6 Social   Person          554
    ##  7 Physical Media           478
    ##  8 Malware  Server          453
    ##  9 Social   Server          375
    ## 10 Malware  User Dev        371
    ## # … with 54 more rows

`enum2grid` replicates the plotting function in `jayjacobs` version, and
will work with all recent versions of R:

``` r
enum2grid(vcdb, c("asset.variety", "actor.external.variety"))
```

![](README_files/figure-markdown_github/unnamed-chunk-10-1.png)

Another example:

``` r
enum2grid(vcdb, c("action", "asset.variety"))
```

![](README_files/figure-markdown_github/unnamed-chunk-11-1.png)

`importveris()` is a thin wrapper over the `json2veris()` function. In
later versions of vcdb incidents, the original function may result in a
dataframe where one or more of its variables is another level of nested
list object(s). This function eliminates these columns, so they’re in a
more ready state for most data analysis tasks:

``` r
vcdb_small <- importveris("~/Datasets/vcdb_small/")
```

    ## [1] "veris dimensions"
    ## [1]    3 2437
    ## named integer(0)
    ## named integer(0)

Credits
-------

-   A big appreciation to [Jay Jacobs](https://github.com/jayjacobs) for
    the original `verisr` package. While it hasn’t receive any updates
    in recent years, the project has been a tremendous help and starting
    point.

-   Thanks to the Verizon RISK Team and the community behind The VERIS
    Community Database

-   Thanks to Hadley Wickham, the contributors and all maintainers of
    packages used in this project

Contributing and Issues
-----------------------

The project is licensed under GPL-2. Please feel free to fork, submit
pull requests or open issues.
