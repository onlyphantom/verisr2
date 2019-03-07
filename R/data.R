#' Data Frame processed from VERIS Community Database
#'
#' A dataset containing the records of 8,198 incidents sampled
#' and made available by the Verizon RISK Team. This dataset is
#' processed into R's data frame format based on the vcdb schema
#' file and updated as of 5 March, 2019.
#'
#' @format A data frame with 8,198 rows and 2,432 variables:
#' \describe{
#'   \item{action.environmental.notes}
#'   \item{action.environmental.variety.Deterioration}
#'   \item{action.environmental.variety.Earthquake}
#'   ...
#' }
#' @source \url{https://github.com/vz-risk/VCDB}
"vcdb"
