#' Extract the name
#'
#' Extract the value (name) from the original representation of an enumeration.
#'
#' @param string Character or vector of characters representing one or more fields of interest (enumeration).
#' @return a character string
#' @examples
#' extract_names("action.hacking.result.Exfiltrate")

extract_names <- function(string) regmatches(string, regexpr(pattern="[[:upper:]]+[A-z ]+[[:alnum:]]", text=string))

#' Find the largest values
#'
#' For each row, find a value that represent the enumeration using \code{max.col}. An internal function that
#' is used in \code{determine_primary} and \code{determine_primaryl}.
#'
#' @param data A \code{data frame} object, where all columns
#' @return a character vector of the values that are largest in its enumeration group
#' @examples
#' find_largest(vcdb[1:10,57:105])

find_largest <- function(data) extract_names(colnames(data)[max.col(data, ties.method="first")])

#' Determine the primary value from each enumeration group (numeric)
#'
#' For each row, find a value that represent the enumeration. If all values in the group is NA, replace
#' with "Unknown" variable
#'
#' @inheritParams getenum_tbl
#' @return a character vector of the values that represent that enumeration for each numeric observation
#' @examples
#' determine_primary(vcdb, "action.hacking.variety")
#' table(determine_primary(vcdb, c("action.hacking.result", "action.hacking.variety")))

determine_primary <- function(data, string){
  y <- getenum_stri(data, string)
  return(ifelse(rowSums(data[,y]) == 0, "Unknown", find_largest(data[,y])))
}

#' Determine the primary value from each enumeration group (logical)
#'
#' For each row, find a value that represent the enumeration. If all values in the group is NA, replace
#' with "Unknown" variable
#'
#' @inheritParams getenum_stri
#' @return a character vector of the values that represent that enumeration for each logical observation
#' @examples
#' determine_primaryl(vcdb, "action.error.variety")

determine_primaryl <- function(data, string){
  result <- vector(mode="character", length=nrow(data))
  y <- getenum_stri(data, string)
  result <- find_largest(data[,y])
  inter <- apply(data[, y], MARGIN=1, FUN=sum)
  result[inter == 0] <- "Unknown"
  result[inter > 1] <- "Multiple"

  return(result)
}

#' Determine the value for impact.overall_amount
#'
#' For each row, find a value that represent the impact.
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @return a data frame
#' @examples
#' determine_primary(vcdb)

determine_impact <- function(data){
  cond1 <- data$impact.overall_amount == 0 &
    (data$impact.overall_max_amount +
       data$impact.overall_max_amount > 0 )

  data[cond1, "impact.overall_amount"] <- round(rowMeans(data[cond1, c("impact.overall_max_amount", "impact.overall_min_amount")]),0)
  return(data)
}

#' Extract all enumerations from a data frame
#'
#' Returns a character vector containing the names of all enumerations
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @return a character vector containing the names of all enumerations
#' @examples
#' extract_enums(vcdb)

extract_enums <- function(vcdb) unique(regmatches(colnames(vcdb),
                                        regexpr(pattern="[a-z._0-9]*(?=\\.[A-Z]+)",
                                                        text=colnames(vcdb), perl = TRUE)))

#' Process all logical enumerations in a data frame
#'
#' Returns a collapsed data frame by selecting a primary value that determine each enumeration
#' across all logical variables
#'
#' @param data A \code{data frame} object, typically converted from the VCDB JSON format.
#' @return a collapsed data frame
#' @examples
#' process_log(vcdb)

process_log <- function(vcdb){
  enum_list <- extract_enums(vcdb)
  for(i in 1:length(enum_list)){
    vcdb[,enum_list[i]] <- determine_primaryl(vcdb, enum_list[i])
  }
  return(vcdb[, enum_list])
}


#' Collapse the VCDB data frame into a more conventional "tidy" data frame
#'
#' Shrink the dimension of a VCDB data frame by using a representative value for each enumeration.
#' This function results in some loss of fidelity, a reasonable trade-off for the convenience we get
#' from a "tidy" data frame.
#'
#' The function handles logical enumerations (TRUE/FALSE) differently from factor enumerations as
#' well as numeric enumerations. The resulting data frame (output) contains new variables not in
#' the original VCDB that stores the "representative" value for each incident across each
#' enumeration group
#'
#' @inheritParams process_log
#' @return a collapsed data frame more suited for tidyverse-esque EDA tasks
#' @examples
#' collapse_vcdb(vcdb)
#' @export


collapse_vcdb <- function(vcdb){
  facts <- vcdb %>%
    select_if(is.logical) %>%
    select_if(~!all(is.na(.))) %>%
    process_log() %>%
    rename("pattern_collapsed"=pattern) %>%
    mutate_if(is.character, as.factor)

  nums <- vcdb %>%
    select_if(is.numeric) %>%
    select_if(~!all(is.na(.))) %>%
    replace(is.na(.), 0) %>%
    determine_impact() %>%
    mutate(
      asset.primary_asset = as.factor(determine_primary(., "asset.assets.amount")),
      attribute.confidentiality.primary_attribute = as.factor(determine_primary(., "attribute.confidentiality.data.amount"))
    ) %>%
    select(
      "asset.primary_asset", "asset.total_amount", "attribute.availability.duration.value", "attribute.confidentiality.data_total", "impact.overall_amount", "timeline.compromise.value", "timeline.discovery.value", "timeline.exfiltration.value", "victim.locations_affected", "victim.revenue.amount", "victim.secondary.amount", "asset.primary_asset", "attribute.confidentiality.primary_attribute"
    )

  x <- vcdb %>%
    mutate(timeline.incident.year = as.factor(timeline.incident.year),
           timeline.incident.month = as.factor(timeline.incident.month),
           timeline.incident.day = as.factor(timeline.incident.day),
           plus.dbir_year = as.factor(plus.dbir_year),
           plus.timeline.notification.day = as.factor(plus.timeline.notification.day),
           plus.timeline.notification.month = as.factor(plus.timeline.notification.month),
           plus.timeline.notification.year = as.factor(plus.timeline.notification.year)) %>%
    select_if(function(col) is.character(col) || is.factor(col))


  vcdb_collapsed <- cbind(facts, nums, x) %>%
    select_if(~!all(is.na(.))) %>%
    select(sort(current_vars()))
  return(vcdb_collapsed)
}


