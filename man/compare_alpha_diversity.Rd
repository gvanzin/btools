% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compare_alpha_diversity.R
\name{compare_alpha_diversity}
\alias{compare_alpha_diversity}
\title{Calculate alpha diversity statistics}
\usage{
compare_alpha_diversity(physeq, x = "Day", group = "Treatment",
  diversity = c("Observed", "Shannon", "Simpson"),
  test_type = c("nonparametric", "parametric"),
  col_var = "PD_whole_tree_alpha", num_perm = 999,
  multiple_corrections = T, write = F, filename = "results", ...)
}
\arguments{
\item{physeq}{A phyloseq object}

\item{x}{Variable that describes Time}

\item{group}{Variable the describes different groups for comparisons}

\item{diversity}{Diversity metric to use for alpha diversity calculations}

\item{test_type}{type of test to use for significance testing}

\item{col_var}{Column name if diversity measurements are in mapping file}

\item{num_perm}{Number of permutations for non parametric tests}

\item{multiple_corrections}{Should multiple comparisons be corrected on pvalues}

\item{write}{Write table to file}

\item{filename}{Filename of the output results table}

\item{...}{Additional arguments}
}
\value{
A dataframe with taxa information and sample metadata
}
\description{
Compute p-values and multiple comparisons adjusted q-values for
two-group comparisons across multiple timepoints.
}

