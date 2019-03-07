#' Import all vcdb incidents is a "ready" data frame
#'
#' This function is a thin wrapper over the json2veris function. In later versions of vcdb incidents,
#' the original function may result in a dataframe where one or more of its variables is another level
#' of nested list object(s). This function eliminates these columns, so they're in a more ready state
#' for most data analysis tasks.
#' '
#' @importFrom verisr json2veris
#' @param dir The directory to list through. This may be a vector of
#' directorites, in which case each all the matching files in each
#' directory will be loaded.
#' @param schema a full veris schema with enumerations included
#' @return a data frame
#' @examples
#' importveris("~/Datasets/vcdb_small/")
#' @export

importveris <- function(dir, schema='data/vcdb-merged.json'){
  data <- verisr::json2veris(dir=dir, schema=schema)
  is_list <- sapply(data, is.list)
  data <- data[, !is_list]
  return(data)
}


