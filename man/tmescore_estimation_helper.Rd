% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tmescore_estimation_helper.R
\name{tmescore_estimation_helper}
\alias{tmescore_estimation_helper}
\title{Calculating TMEscore using PCR data}
\usage{
tmescore_estimation_helper(
  pdata = NULL,
  eset,
  signature,
  mini_gene_count,
  column_of_sample,
  scale = FALSE,
  method = "mean",
  adjust_eset = TRUE,
  log2trans = FALSE
)
}
\arguments{
\item{pdata}{phenotype data of input sample;
if phenotype data is NULL, create a data frame with `Index` and `ID` contain column names of eset}

\item{eset}{normalizaed  transcriptomic data: normalized (CPM, TPM, RPKM, FPKM, etc.)}

\item{signature}{List of gene signatures}

\item{mini_gene_count}{filter out signatures with genes less than minimal gene in expression set;}

\item{column_of_sample}{Defines in which column of pdata the sample identifier can be found}

\item{scale}{default is FALSE}

\item{method}{default is TRUE}

\item{adjust_eset}{remove variables with missing value, sd =0, and Inf value}

\item{log2trans}{default is FALSE}
}
\value{
data frame with pdata and signature scores for gene sets; signatures in columns, samples in rows
}
\description{
Calculating TMEscore using PCR data
}
\examples{

}
\author{
Dongqiang Zeng
}
