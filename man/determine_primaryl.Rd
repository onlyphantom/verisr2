% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/collapse.R
\name{determine_primaryl}
\alias{determine_primaryl}
\title{Determine the primary value from each enumeration group (logical)}
\usage{
determine_primaryl(data, string)
}
\arguments{
\item{data}{A \code{data frame} object, typically converted from the VCDB JSON format.}

\item{string}{Character or vector of characters representing one or more fields of interest (enumeration).}
}
\value{
a character vector of the values that represent that enumeration for each logical observation
}
\description{
For each row, find a value that represent the enumeration. If all values in the group is NA, replace
with "Unknown" variable
}
\examples{
determine_primaryl(vcdb, "action.error.variety")
}
