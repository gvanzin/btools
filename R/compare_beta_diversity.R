# @ Thomas W. Battaglia

#' Calculate beta diversity statistics over time.
#'
#' Compute p-values and multiple comparisons adjusted q-values for
#' two-group comparisons using PERMANOVA on beta diversity metrics across multiple timepoints.
#'
#' @param phylo A phyloseq object
#' @param x The variable that describes Time
#' @param group The variable that describes 2 or more groups
#' @param test The PERMANOVA test to use.
#' @param bdiv Beta diversity metric to calculate significance.
#' @param write Should results be written to a file in the current working directory.
#' @param filename The name of the output file if write is TRUE.
#' @param fdr Should FDR correction be applied.
#' @param fdr_test The test to use to correct for multiple comparisons. Default is FDR.
#' @param seed The seed number to use when calculating beta diversity metrics. Default is 918.
#' @param ... Any additional arguments for external functions.
#' @return A dataframe for an PERMANOVA test over each timepoint from each two group comparison.
#' @export
compare_beta_diversity <- function(phylo,
                                   x = as.character(),
                                   group = as.character(),
                                   test = c("adonis", "anosim"),
                                   bdiv = c("weighted", "unweighted"),
                                   write = F,
                                   filename = "results",
                                   fdr = T,
                                   fdr_test = "fdr",
                                   seed = 918, ...){

  # Get samples metadata into dataframe
  metadata <- as(phyloseq::sample_data(phylo), "data.frame")

  # VADLIDATION (TODO)

  # Assign variable to weighted/unweighted choice
  if(bdiv == "unweighted"){
    weighted = FALSE
  } else if(bdiv == "weighted"){
    weighted = TRUE
  } else{
    stop("Error processing beta diversity choice. Please be sure your input is correct.")
  }

  # Split table according to timepoint variable
  sptables <- split(metadata, metadata[[x]], drop = T)

  # Iterate over each time point and apply significance function
  final <- do.call(rbind, lapply(sptables, function(data) {

    # Drop unused levels from metadata
    data[[group]] <- droplevels(data[[group]])

    # Get levels for comparisons
    comparing_groups <- levels(data[[group]])

    # Check number of levels
    if(length(comparing_groups) <= 1){
      message("Not enough factors, skipping this timepoint", appendLF = T)
      return(NULL)
    }

    # Find each 2 group comparison
    comparison_list <- combn(comparing_groups, 2, simplify = F)

    # Iterate over 2 group comparisons for one time point
    do.call(rbind, lapply(comparison_list, function(combination){

      # Subset metadata and apply to phyloseq object
      metatable_sub <- subset(data, data[[group]] %in% combination, droplevels = T)
      phylo0 = phylo
      phyloseq::sample_data(phylo0) <- metatable_sub

      # Run Unifrac
      set.seed(seed)
      unifrac <- phyloseq::UniFrac(phylo0, weighted = weighted)

      # Print message
      message(paste("Comparing:",
                    combination[1], "vs", combination[2] ,
                    "at",
                    as.character(x), unique(metatable_sub[[x]]), sep = " "),
              appendLF = T)

      # Caculate tests
      if(test == "adonis"){
        return(adonis_test(dm = unifrac,
                           meta = metatable_sub,
                           group = group,
                           x = x,
                           time = unique(metatable_sub[[x]]), 
                           combination1 = as.character(combination[1]),
                           combination2 = as.character(combination[2])))
      }
      if(test == "anosim"){
        return(anosim_test(dm = unifrac,
                           meta = metatable_sub,
                           group = group,
                           x = x,
                           time = unique(metatable_sub[[x]]), 
                           combination1 = as.character(combination[1]),
                           combination2 = as.character(combination[2])))
      }

    })) # end of 2-group comparison iteration

  })) # end of time iteration

  message("Iterations completed...")

  # Correction for multiple comparisons
  if(fdr == TRUE){
    message("Appying multiple-testing corrections...")
    final$padj <- p.adjust(final$pvalue, method = fdr_test)
  }

  # Write results to file
  write.table(final, paste0(filename, '.txt'), quote = F, sep = '\t', row.names = F)
  return(final)

} # End of main function

# Function for calculating adonis p-values
adonis_test <- function(dm, meta, group, x, time, combination1, combination2){
  
  # Try comparisons
  results <- suppressWarnings(try(vegan::adonis(formula = as.dist(dm) ~ meta[[group]], permutations = 999)))
  #results2 <- suppressWarnings(try(vegan::permutest(betadisper(as.dist(dm), metadata[["number"]]))))

  # If error write NA's to results
  if(class(results) == "try-error"){
    pval <- 'NA'
    SumsOfSqs <- "NA"
    MeanSqs <- "NA"
    F.Model <- "NA"
    R2 <- "NA"
  }

  # If no error, assign results to variables
  if(class(results) == "adonis") {
    pval <- results$aov.tab$`Pr(>F)`[1]
    SumsOfSqs <- results$aov.tab$SumsOfSqs[1]
    MeanSqs <- results$aov.tab$MeanSqs[1]
    F.Model <- results$aov.tab$F.Model[1]
    R2 <- results$aov.tab$R2[1]
  }

  # Place results into dataframe
  results_mat <- data.frame(Group1 = as.character(combination1),
                            Group2 = as.character(combination2),
                            x = time,
                            n = nrow(meta),
                            SumsOfSqs = SumsOfSqs,
                            MeanSqs = MeanSqs,
                            F.Model = F.Model,
                            R2 = R2,
                            pvalue = pval)
  return(results_mat)
}

# Function for calculating anosim p-values
anosim_test <- function(dm, meta, group, x, time, combination1, combination2){

  # Try comparisons
  results <- suppressWarnings(try(vegan::anosim(as.dist(dm), meta[[group]], permutations = 999)))

  # If too little amount of samples are present for either group, result in None.
  if(class(results) == "try-error"){
    pval <- 'NA'
    R_value <- "NA"
  }

  # If no error, assign results to variables
  if(class(results) == "anosim"){
    pval <- results$signif
    R_value <- results$statistic
  }

  # Place results into dataframe
  results_mat <- data.frame(Group1 = combination1,
                            Group2 = combination2,
                            x = time,
                            n = nrow(meta),
                            R_value = R_value,
                            pvalue = pval)

  return(results_mat)
}

