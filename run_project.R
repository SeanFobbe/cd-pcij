#'# Load Package
library(rmarkdown)

#+
#'# Data Set
#' To compile the full data set and generate a PDF report, copy all files provided in the Source ZIP Archive into an empty (!) folder and use the command below from within an R session:

#+ eval = FALSE

rmarkdown::render(input = "CD-PCIJ_Source_CorpusCreation.R",
                  output_file = "CD-PCIJ_1-0-0_CompilationReport.pdf",
                  envir = new.env())



#+
#'# Codebook
#' To compile the Codebook, after you have run the Corpus Creation script, use the command below from within an R session:

#+ eval = FALSE

rmarkdown::render(input = "CD-PCIJ_Source_CodebookCreation.R",
                  output_file = "CD-PCIJ_1-0-0_Codebook.pdf",
                  envir = new.env())
