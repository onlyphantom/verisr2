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

# .onAttach <- function(libname, pkgname) {
#   packageStartupMessage("Welcome to verisr2. This package is written to add or replace functionalities broken in the old veris package by Jay Jacobs which included many legacy code that has been deprecated. Please file issues on GitHub.")
# }

#' Find all variables in a VCDB data frame from a specified enumeration
#'
#' Find all fields from the data frame where its field name
#' is immediately preceded by the specified string.
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @param string Character or vector of characters representing one or more fields of interest (enumeration).
#' @return a character vector of all variables in the VCDB dataframe that has the speficied enumeration
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
#' @param params Character or vector of characters representing one or more fields of interest (enumeration)
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
#' @param params Character representing the fields of interest (enumeration).
#' @inheritParams getenum_tbl
#' @return a data frame with count and frequency from enumerating on one field.
#' @examples
#' getenum_df_single(vcdb, "actor.external.variety")
#' @seealso \code{\link{getenum_df}} for a more generalized implementation of this function

getenum_df_single <- function(data, params){
  sel <- getenum_stri(data, params)
  selnames <- gsub("^[a-z0-9._ ]+\\.?(?=[A-Z])", replacement="", sel, perl=TRUE)

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


#' Identify all notes columns
#'
#' Identify all notes columns
#'
#' @return a vector of character containing columns names that are "notes"
#' @examples
#' notes_only()
#'
#' @seealso \code{\link{involving_country}} where this function is being used

notes_only <- function(){
  pat <-  ".*[._]{1}(?=notes$)"
  matches <- regmatches(colnames(vcdb),
                        regexpr(pat,colnames(vcdb),
                                perl = TRUE))
  matches_list <- unique(matches)
  matches_list <- unname(sapply(matches_list, function(x){
    paste0(x, "notes")
  }))

  c("notes","summary",matches_list)
}

#' Find all incidents involing a specified country, optionally returning only
#' notes-type columns
#'
#' A function that returns all incidents involving a country, where said country
#' could be a victim, target, conspirator, owner of assets etc.
#'
#' When \code{ notes_only } is TRUE, the returned data frame will contain only
#' columns derived from "notes" relating to the event. The function also helpfully
#' drop any rows (incident) where all columns values were NA, which indicates
#' that the incident was reported without any notes.
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @param code Two-letter country codes, e.g "US", "ID" etc
#' @return a data frame containing incidents where the specified country is involved
#' @examples
#' involving_country(vcdb, "US", notes_only=TRUE)
#' involving_country(vcdb, "ID")
#' @export

involving_country <- function(data, code, notes_only=FALSE){
  code <- toupper(code)
  pat = ".*(?=.country.[A-Z]{2}$)"
  matches <- regmatches(colnames(data),
                        regexpr(pat,colnames(data),
                                perl = TRUE))
  matches_list <- unique(matches)
  cols_list <- unname(sapply(matches_list, function(x, y=code){
    paste0(x, ".country.", code)
  }))

  if (notes_only == TRUE) {
    colx <- notes_only()
    data <- data[which(rowSums(data[,cols_list]) > 0), colx]
    data[!(rowSums(is.na(data))==ncol(data)),]
  } else{
    data[which(rowSums(data[,cols_list]) > 0), ]
  }

}

