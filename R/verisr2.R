#' verisr2: Convenience functions for exploratory analysis on VERIS database
#'
#' @section Motivation:
#' The package replicates in base R or dplyr many of the helper functions originally
#' implemented in the verisr package by Jay Jacobs. The original package by Jay uses
#' data.table code that is deprecated and no longer works. The author has stated his
#' desire to one day rewrite these functions in dplyr code but since effort on that
#' has been stagnant for a few years now (5 years as of writing) this is a simple
#' attempt to recreate these helper functions in dplyr or base R code.
#'
#' @docType package
#' @name verisr2
NULL

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Welcome to verisr2. To transform veris JSON to data frame, use the veris package from https://github.com/vz-risk/verisr. Since the old veris package is no longer maintained, this package is written to add or replace functionalities broken in the old veris package which included many legacy code that has been deprecated.")
}

#' Find all variables in a VCDB data frame from a specified prefix
#'
#' Find all fields from the data frame where its field name
#' is immediately preceded by the specified string.
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @param string Character or vector of characters representing one or more fields of interest (prefix).
#' @return a character vector of all variables in the VCDB dataframe that has the speficied prefix
#' @examples
#' getenum_stri(vcdb, "action.error.vector")
#' getenum_stri (vcdb, "actor")
#' @export

getenum_stri <- function(data, string){
  reg <- c()
  coln <- c()
  for(i in 1:length(string)){
    string[i] <- as.character(string[i])

    reg[i] <- paste("^",string[i],"\\.[A-Z]", sep = "")
    coln <- c(coln, colnames(data)[grep(reg[i], colnames(data))])
  }
  return(coln)
}

#' A frequency count table from one or more enumerations
#'
#' Generate counts from the values given one or more enumerations
#' is immediately preceded by the specified string.
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format
#' @param params Character or vector of characters representing one or more fields of interest (prefix)
#' @return a frequency table from enumerating on the specified fields of interests
#' @examples
#' getenum_tbl(vcdb, c("actor"))
#' getenum_tbl(vcdb, c("action", "asset.variety"))
#' @export

getenum_tbl <- function(data, params){
  sel <- getenum_stri(data, params)
  sel <- getenum_stri(data, params)
  colSums(data[,sel])
}

#' Generate a data.frame of counts from an enumeration.
#'
#' Generate counts from the values given one enumeration and return both
#' the count and proportion. Replicates in base R the getenum.single function
#' from verisr which referenced deprecated code from data.table.
#'
#' You almost always want to use \code{getenum_df} instead, which is a more generalized wrapper
#' that returns an identical data frame when called with one field.
#' @import dplyr
#' @import tidyr
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @param params Character representing the fieldsof interest (prefix).
#' @inheritParams getenum_tbl
#' @return a data frame with count and frequency from enumerating on one field.
#' @examples
#' getenum_df_single(vcdb, "actor.external.variety")
#' @seealso \code{\link{getenum_df}} for a more generalized implementation of this function

getenum_df_single <- function(data, params){
  sel <- getenum_stri(data, params)
  selnames <- gsub("^[a-z.]+", replacement="", sel)

  x <- data.frame("enum" = selnames, "x"=colSums(data[,sel]))
  x <- cbind(x, "n"=nrow(data[rowSums(data[,sel[-length(sel)]]) > 0, ]))
  x$freq <- round(x$x/x$n,5)
  x[x$enum == "Unknown", c("n", "freq")] <- NA
  x <- x[order(x$n, -x$x, na.last = TRUE), ]

  row.names(x) <- NULL
  return(x)
}

#' Generate a data.frame of counts from one or two enumerations.
#'
#' Generate counts from the values given one or two enumerations and return both
#' the count and proportion. Replicates in dplyr the original getenum function
#' from verisr which referenced deprecated code from data.table.
#'
#' @inheritParams getenum_tbl
#' @import dplyr
#' @import tidyr
#' @return a data frame with count and frequency from enumerating on one or more fields.
#' @examples
#' getenum_df(vcdb, "asset.variety")
#' getenum_df(vcdb, c("action", "asset.variety"))
#' @export

getenum_df <- function(data, params){
  if(length(params) > 2){
    stop("The aggregate-by-enumeration function extracts counts by enumerating over at most 2 enumerations. More than 2 are given in the function call.")
  }else if(length(params)==1) {
    getenum_df_single(data, params)
  }else{
    sel <- getenum_stri(data, params)

    p1 <- as.character(params[1])
    p2 <- as.character(params[2])

    y <- data[,sel] %>%
      gather("x", x_val, starts_with(p1)) %>%
      gather("y", y_val,  starts_with(p2)) %>%
      separate(x, into = c("xvar", "type"), sep = "\\.(?=[A-Z])") %>%
      separate(y, into = c("yvar", "type2"), sep = "\\.(?=[A-Z])") %>%
      select(par1=type, par2=type2, x_val, y_val) %>%
      mutate("val"= (x_val+y_val > 1)) %>%
      group_by(par1, par2) %>%
      summarize(n=sum(val)) %>%
      arrange(-n) %>%
      ungroup()

    colnames(y) <- c(p1,p2,"x")
    return(y)
  }
}



