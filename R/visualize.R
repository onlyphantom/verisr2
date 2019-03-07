#' Generate a 2x2 ggplot2 grid
#'
#' Create an a4 grid (see Verizon's Data Breach Inves 2012) and return a ggplot object.
#' Replicates the plota4 function from verisr which referenced deprecated code from data.table.
#'
#' @import ggplot2
#' @inheritParams getenum_tbl
#' @return a ggplot object
#' @examples
#' enum2grid(vcdb, c("action", "asset.variety"))
#' enum2grid(vcdb, c("asset.variety", "actor.external.variety"))
#' @export

enum2grid <- function(data, params){
  x <- getenum_df(data, params)
  if(length(params) != 2){
    stop("This function produces a 2x2 grid based on the output of 2 enumerations. Exactly 2(two) parameters must be given in the function call.")
  }else{
    ggplot(x, aes_string(x=params[1], y=params[2]))+
      geom_tile(fill="white", color="gray80", aes(fill=x)) +
      geom_tile(data=x[x$x != 0, ], color="gray80", aes(fill=x)) +
      geom_text(color="white", aes(label=x)) +
      scale_fill_gradient(low = "azure3", high = "black") +
      theme_linedraw()
  }
}

