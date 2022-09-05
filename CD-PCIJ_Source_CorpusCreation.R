#'---
#'title: "Compilation Report | Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ)"
#'author: Seán Fobbe
#'geometry: margin=3cm
#'papersize: a4
#'fontsize: 11pt
#'output:
#'  pdf_document:
#'    keep_tex: true
#'    toc: true
#'    toc_depth: 3
#'    number_sections: true
#'    pandoc_args: --listings
#'    includes:
#'      in_header: tex/CD-PCIJ_Source_TEX_Preamble_EN.tex
#'      before_body: [tex/CD-PCIJ_Source_TEX_Author.tex,tex/CD-PCIJ_Source_TEX_Definitions.tex,tex/CD-PCIJ_Source_TEX_CompilationTitle.tex]
#'bibliography: packages.bib
#'nocite: '@*' 
#'---


#'\newpage

cat(readLines("README.md"),
    sep = "\n")



#'\newpage
#'# Preamble

#+
#'## Datestamp
#' The datestamp is set at the beginning of the script so it will be held constant even if long runtime breaks the date barrier.

datestamp <- Sys.Date()
print(datestamp)



#+
#'## Date and Time (Begin)
begin.script <- Sys.time()
print(begin.script)




#+
#'## Load Packages

library(httr)          # HTTP Tools
library(rvest)         # Web Scraping
library(mgsub)         # Vectorized Gsub
library(stringr)       # String Manipulation
library(pdftools)      # PDF utilities
library(fs)            # File Operations
library(knitr)         # Scientific Reporting
library(kableExtra)    # Enhanced Knitr Tables
library(magick)        # Required for cropping when compiling PDF
library(DiagrammeR)    # Graph/Network Visualization 
library(DiagrammeRsvg) # Export DiagrammeR Graphs as SVG
library(rsvg)          # Render SVG to PDF
library(ggplot2)       # Advanced Plotting
library(scales)        # Rescaling of Plots
library(viridis)       # Viridis Color Palette
library(RColorBrewer)  # ColorBrewer Palette
library(readtext)      # Read TXT Files
library(quanteda)      # Advanced Text Analytics
library(quanteda.textstats)  # Text Statistics Tools
library(quanteda.textplots)  # Specialized Plots for Text Statistics
library(textcat)       # Classify Text Language
library(data.table)    # Advanced Data Handling
library(doParallel)    # Parallelization


#'## Load Additional Functions
#' **Note:** Each custom function will be printed in full prior to its first use in order to enhance readability. All custom functions are prefixed with \enquote{f.} for clarity.

source("functions/f.boxplot.body.R")
source("functions/f.boxplot.outliers.R")
source("functions/f.dopar.multihashes.R")
source("functions/f.dopar.pagenums.R")
source("functions/f.dopar.pdfextract.R")
source("functions/f.dopar.pdfocr.R")
source("functions/f.fast.freqtable.R")
source("functions/f.hyphen.remove.R")
source("functions/f.lingsummarize.iterator.R")
source("functions/f.linkextract.R")
source("functions/f.special.replace.R")
source("functions/f.token.processor.R")


#+
#'# Parameters

#+
#'## Read Configuration File
#' All configuration options are set in a separate configuration file that is read here. They should only be changed in that file!
#'
#' The configuration is read, printed, re-written to a temporary file and re-read to achieve transposition with correct column classes, something fread() cannot do directly. This procedure allows for a source CSV file that is easier to edit and easier to access within R.

config <- fread("CD-PCIJ_Source_Config.csv")

kable(config,
      format = "latex",
      align = c("p{5cm}",
                "p{9cm}"),
      booktabs = TRUE,
      col.names = c("Key",
                    "Value"))

temp <- transpose(config,
                  make.names = "key")

fwrite(temp,
       "temp.csv")

config <- fread("temp.csv")

unlink("temp.csv")





#+
#'## Name of Data Set

datashort <- config$datashort
print(datashort)

#'## Version Number

version <- config$version
print(version)

#'## Create Version Number with Dashes
#' This is used in output files.

version.dash <- gsub("\\.",
                     "-",
                     version)
print(version.dash)


#'## DOI of Data Set Concept

doi.concept <- config$doi.data.concept
print(doi.concept)


#'## DOI of Specific Version

doi.version <- config$doi.data.version
print(doi.version)


#'## License
license <- config$license
print(license)


#'## Output Directory
#' The directory name must include a terminating slash!
outputdir <- paste0(getwd(),
                    "/ANALYSIS/") 


#'## DPI for OCR
#' This is the resolution at which PDF files will be converted to TIFF during the OCR step. DPI values will significantly affect the quality of text ouput and file size. Higher DPI requires more RAM, means higher quality text and greater PDF file size. A value of 300 is recommended.

ocr.dpi <- config$ocr.dpi
print(ocr.dpi)




#'## Frequency Tables: Ignored Variables

#' This is a character vector of variable names that will be ignored in the construction of frequency tables.
#'
#' It is a good idea to add variables to this list that are unlikely to produce useful frequency tables. This is often the case for variables with a very large proportion of unique values. Use this option judiciously, as frequency tables are useful for detecting anomalies in the metadata.


freq.var.ignore <- unlist(tstrsplit(config$freq.var.ignore,
                                split = " "))

print(freq.var.ignore)




#'## Knitr Options

#+
#'### Image Output File Formats

plot.format <- unlist(tstrsplit(config$plot.format,
                                split = " "))

print(plot.format)


#'### DPI for Raster Graphics

plot.dpi <- config$plot.dpi
print(plot.dpi)



#'### Alignment of Diagrams in Report

fig.align <- config$fig.align
print(fig.align)




#'### Set Knitr Options
knitr::opts_chunk$set(fig.path = outputdir,
                      dev = plot.format,
                      dpi = plot.dpi,
                      fig.align = fig.align)






#'## LaTeX Configuration
#' These LaTeX definitions are used for the cover and inside cover.

#+
#'### Construct LaTeX Definitions

latexdefs <- c("%===========================\n% Definitions\n%===========================",
               "\n% NOTE: This file was created automatically during the compilation process.\n",
               "\n%-----Version-----",
               paste0("\\newcommand{\\version}{",
                      config$version,
                      "}"),
               "\n%-----Titles-----",
               paste0("\\newcommand{\\datatitle}{",
                      config$datatitle,
                      "}"),
               paste0("\\newcommand{\\datashort}{",
                      config$datashort,
                      "}"),
               paste0("\\newcommand{\\softwaretitle}{Source Code for the \\enquote{",
                      config$datatitle,
                      "}}"),
               paste0("\\newcommand{\\softwareshort}{",
                      config$datashort,
                      "-Source}"),
               "\n%-----Data DOIs-----",
               paste0("\\newcommand{\\dataconceptdoi}{",
                      config$doi.data.concept,
                      "}"),
               paste0("\\newcommand{\\dataversiondoi}{",
                      config$doi.data.version,
                      "}"),
               paste0("\\newcommand{\\dataconcepturldoi}{https://doi.org/",
                      config$doi.data.concept,
                      "}"),
               paste0("\\newcommand{\\dataversionurldoi}{https://doi.org/",
                      config$doi.data.version,
                      "}"),
               "\n%-----Software DOIs-----",
               paste0("\\newcommand{\\softwareconceptdoi}{",
                      config$doi.software.concept,
                      "}"),
               paste0("\\newcommand{\\softwareversiondoi}{",
                      config$doi.software.version,
                      "}"),

               paste0("\\newcommand{\\softwareconcepturldoi}{https://doi.org/",
                      config$doi.software.concept,
                      "}"),
               paste0("\\newcommand{\\softwareversionurldoi}{https://doi.org/",
                      config$doi.software.version,
                      "}"))



#'\newpage
#'### Write LaTeX Definitions

writeLines(latexdefs,
           "tex/CD-PCIJ_Source_TEX_Definitions.tex")




#'## Write Package Citations
knitr::write_bib(c(.packages()),
                 "packages.bib")







#'# Parallelization
#' Parallelization is used for many tasks in this script, e.g. for accelerating the conversion from PDF to TXT, OCR, analysis with **quanteda** and with **data.table**. The maximum number of cores will automatically be detected and used.
#'
#' The download of decisions from the ICJ website is not parallelized to ensure respectful use of the Court's bandwidth.
#'
#' The use of **fork clusters** is significantly more efficient than PSOCK clusters, although it restricts use of this script to Linux systems.

#+
#'### Detect Number of Logical Cores
#' This will detect the maximum number of threads (= logical cores) available on the system.

fullCores <- detectCores()
print(fullCores)

#'### Set Number of OCR Control Cores
#' **Note:** Reduced number of control cores for OCR, as Tesseract calls up to four threads by itself.
ocrCores <- round((fullCores / 4)) + 1  
print(ocrCores)

#'### Data.table
setDTthreads(threads = fullCores)

#'### Quanteda
quanteda_options(threads = fullCores)    





#'# Create Directories

#+
#'## Define Set of Data Directories

dirset <- c("MULT_PDF_ORIGINAL_FULL",
             "EN_PDF_ENHANCED_FULL",
             "FR_PDF_ENHANCED_FULL",
             "EN_PDF_ORIGINALSPLIT_FULL",
             "FR_PDF_ORIGINALSPLIT_FULL",
             "EN_PDF_ENHANCED_MajorityOpinions",
             "FR_PDF_ENHANCED_MajorityOpinions",
             "EN_TXT_TESSERACT_FULL",
             "FR_TXT_TESSERACT_FULL",
             "EN_TXT_EXTRACTED_FULL",
             "FR_TXT_EXTRACTED_FULL")


#'## Create Data Directories

for (dir in dirset){
    dir.create(dir)
    }



#'## Create Output Directory
dir.create(outputdir)





#'# Visualize Corpus Creation Process



workflow <- "
digraph workflow {

  # Graph Statement
  graph [layout = dot, overlap = false]

  # Legend

  subgraph cluster1{
      peripheries=1
  9991 [label = 'Data Nodes', shape = 'ellipse', fontsize = 22]
  9992 [label = 'Action Nodes', shape = 'box', fontsize = 22]
}


  # Data Nodes

  node[shape = 'ellipse', fontsize = 22]

  A [label = 'www.icj-cij.org']
  B [label = 'Raw PDF Files']
  C [label = 'Labelling Information']
  D [label = 'MULT_PDF_ORIGINAL_FULL']
  E [label = 'Split Instructions']
  F [label = 'EN_PDF_ORIGINALSPLIT']
  G [label = 'FR_PDF_ORIGINALSPLIT']
  H [label = 'EN_TXT_EXTRACTED']
  I [label = 'FR_TXT_EXTRACTED']
  J [label = 'EN_TXT_TESSERACT']
  K [label = 'FR_TXT_TESSERACT']
  L [label = 'EN_PDF_ENHANCED_FULL']
  M [label = 'FR_PDF_ENHANCED_FULL']
  N [label = 'EN_PDF_ENHANCED_MajorityOpinions']
  O [label = 'FR_PDF_ENHANCED_MajorityOpinions']
  P [label = 'Frequency Tables']
  Q [label = 'EN_CSV_TESSERACT_FULL']
  R [label = 'FR_CSV_TESSERACT_FULL']
  S [label = 'EN_CSV_TESSERACT_META']
  T [label = 'FR_CSV_TESSERACT_META']
  U  [label = 'ANALYSIS']


  # Action Nodes

  node[shape = 'box', fontsize = 22]

  0 [label = 'Download Module']
  1 [label = 'Labelling Module']
  2 [label = 'Strict REGEX Validation: Codebook File Name Schema']
  3 [label = 'File Split Module']
  4 [label = 'Detect Missing Language Counterparts']
  5 [label = 'Text Extraction Module']
  6 [label = 'Tesseract OCR Module']
  7 [label = 'Create Majority Variant']
  8 [label = 'OCR Quality Control Module']
  81 [label = 'Clean Texts']
  9 [label = 'Language Purity Module']
  10 [label = 'Add Metadata']
  11 [label = 'Calculate Frequency Tables']
  12 [label = 'Visualize Frequency Tables']
  13 [label = 'Calculate and Add Summary Statistics']
  14 [label = 'Calculate Token Frequencies']
  15 [label = 'Calculate Document Similarity']
  16 [label = 'Write CSV Files']

  # Edge Statements
  A -> 0 -> B
  {B,C} -> 1 -> 2 -> D
  {D,E} -> 3
  3 -> {F,G} -> 4
  4 -> 5 ->{H,I}
  4 -> 6 -> {J,K,L,M}
  {L,M} -> 7 -> {N,O}
  {H, I, J, K} -> 8
  {J,K} -> 81 -> 9 -> 10 -> 11 -> P -> 12
  10 -> {14,15}
  10 -> 13 -> 16
  16 ->{Q,R,S,T}
  {P, 11, 12, 13, 14, 15} -> U
}
"



grViz(workflow) %>% export_svg %>% charToRaw %>% rsvg_pdf("ANALYSIS/CD-PCIJ_Workflow.pdf")
grViz(workflow) %>% export_svg %>% charToRaw %>% rsvg_png("ANALYSIS/CD-PCIJ_Workflow.png")




#' \begin{sidewaysfigure}
#'\includegraphics{ANALYSIS/CD-PCIJ_Workflow.pdf}
#'  \caption{CD-PCIJ: Workflow Schematic}
#' \end{sidewaysfigure}










#'# Download Files


#+
#'## Show Function: f.linkextract
print(f.linkextract)


#'## Acquire Download Links

#+
#'### Series A

URL1 <- c("https://www.icj-cij.org/en/pcij-series-a")

volatile <- f.linkextract(URL1)

links.a <- grep("files",
                volatile,
                ignore.case = TRUE,
                value = TRUE)

Sys.sleep(runif(1, 1, 3))



#'### Series B

URL2 <- c("https://www.icj-cij.org/en/pcij-series-b")

volatile <- f.linkextract(URL2)

links.b <- grep("files",
                volatile,
                ignore.case = TRUE,
                value = TRUE)

Sys.sleep(runif(1, 1, 3))



#'### Series AB

URL3 <- c("https://www.icj-cij.org/en/pcij-series-ab")

volatile <- f.linkextract(URL3)

links.ab <- grep("files",
                 volatile,
                 ignore.case = TRUE,
                 value = TRUE)


#'## Combine 

links.pcij <- c(links.a,
                links.b,
                links.ab)



#'## Clean Links and Names

links.unique <- unique(links.pcij)

links.download <- paste0("https://www.icj-cij.org",
                         links.unique)

names.download <- make.unique(basename(links.download),
                              sep = "--")



#'## Create Download Table
dt <- data.table(links.download,
                 names.download)


#'## Timestamp (Download Begin)
begin.download <- Sys.time()
print(begin.download)


#'## Execute Download

for (i in sample(dt[,.N])){
    
    download.file(dt$links.download[i],
                  dt$names.download[i])
    
    Sys.sleep(runif(1, 0.5, 1.5))
    
}





#'## Timestamp (Download End)
end.download <- Sys.time()
print(end.download)


#'## Duration (Download)
end.download - begin.download





#'## Download Result

#+
#'### Number of Files to Download
download.expected.N <- dt[,.N]
print(download.expected.N)

#'### Number of Files Successfully Downloaded
files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

download.success.N <- length(files.pdf)
print(download.success.N)

#'### Number of Missing Files
missing.N <- download.expected.N - download.success.N
print(missing.N)

#'### Names of Missing Files
missing.names <- setdiff(dt$names.download,
                         files.pdf)
print(missing.names)





#'## Timestamp (Retry Download Begin)
begin.download <- Sys.time()
print(begin.download)


#'## Retry Download

if(missing.N > 0){

    dt.retry <- dt[names.download %in% missing.names]
    
    for (i in 1:dt.retry[,.N]){
        response <- GET(dt.retry$links.download[i])
        Sys.sleep(runif(1, 0.25, 0.75))
        if (response$headers$"content-type" == "application/pdf" & response$status_code == 200){
            tryCatch({download.file(url = dt.retry$links.download[i], destfile = dt.retry$names.download[i])
            },
            error=function(cond) {
                return(NA)}
            )     
        }else{
            print(paste0(dt.retry$names.download[i], " : no PDF available"))  
        }
        Sys.sleep(runif(1, 0.5, 1.5))
    } 
}


#'## Timestamp (Retry Download End)
end.download <- Sys.time()
print(end.download)

#'## Duration (Retry Download)
end.download - begin.download



#'## Retry Result

files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

#'### Successful during Retry

retry.success.names <- files.pdf[files.pdf %in% missing.names]
print(retry.success.names)

#'### Missing after Retry

retry.missing.names <- setdiff(retry.success.names,
                               missing.names)
print(retry.missing.names)






#'## Final Download Result

#+
#'### Number of Files to Download
download.expected.N <- dt[,.N]
print(download.expected.N)

#'### Number of Files Successfully Downloaded
files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

download.success.N <- length(files.pdf)
print(download.success.N)

#'### Number of Missing Files
missing.N <- download.expected.N - download.success.N
print(missing.N)

#'### Names of Missing Files
missing.names <- setdiff(dt$names.download,
                         files.pdf)
print(missing.names)







#'# Labelling Module
#' While the files *are* labelled semantically, the filenames contain almost no useful machine-readable information. This module applies complex hand-coded filenames to all documents in the collection. Filenames are designed to be fully interoperable with the "Corpus of Decisions: International Court of Justice (CD-ICJ)".

#+
#'## Manual Coding

##########################################
###  HAND CODING OF  FILENAMES
##########################################


#+
#'## Read Enhanced Filenames

filenames.enhanced <- fread("data/CD-PCIJ_Source_Filenames-FullNames-SplitInstructions.csv",
                            header = TRUE)[,.(oldname, newname)]



#'## Strictly Validate Naming Scheme with REGEX
#' Test strict compliance with variable types described in Codebook. This should be an empty character vector!

#+
#'### Execute Validation


regex.test <- grep(paste0("^PCIJ", # var: court
                          "_",
                          "(A|B|AB)", # var: series
                          "_",
                          "[0-9]{2}", # var: seriesno
                          "_",
                          "[A-Za-z0-9-]+", # var: shortname
                          "_",
                          "[A-Z-]+", # var: applicant
                          "_",
                          "[A-Z]+", # var: respondent
                          "_",
                          "[0-9]{4}-[0-9]{2}-[0-9]{2}", # var: date
                          "_",
                          "[A-Z]{3}", # var: doctype
                          "_",
                          "[0-9]{2}", # var: collision
                          "_",
                          "(SE|IN|AJ|EV|EX|JO|IM|TL|DH|PR|DI|PO|ME|NA|EV-SE|TL-DH|JO-TL)", # var: stage
                          "_",
                          "[A-Z0-9]{2}", # var: opinion
                          "_",
                          "(EN|FR|DE|BI)", # var: language
                          ".pdf$"),
                   filenames.enhanced$newname,
                   value = TRUE,
                   invert = TRUE)




#'### Results of Validation
print(regex.test)



#'### Stop Script on Failure

if (length(regex.test) != 0){
    stop("REGEX VALIDATION FAILED: FILE NAMES NOT IN COMPLIANCE WITH CODEBOOK SCHEMA!")
    }



#'## Execute Rename
#+ results = "hide"
file.rename(filenames.enhanced$oldname,
            filenames.enhanced$newname)





#'# File Split Module
#' Multilingual original files need to be split into monolingual documents as most current natural language processing techniques work best with monolingual data.

#+
#'## Manual Coding

##########################################
###  HANDCODING OF  Split Instructions
##########################################

#+
#'## Read Instructions

split <- fread("data/CD-PCIJ_Source_Filenames-FullNames-SplitInstructions.csv",
                            header = TRUE)[,.(newname, split)]


#'## No Split
#' These files will not be split. They are monolingual in the original.

nosplit <- split[split == "nosplit"]$newname
print(nosplit)


#'## Custom Parameters for Split
#' These files require custom parameters for splitting due to their non-standard composition.

customsplit <- split[split == "customsplit"]$newname
print(customsplit)


#'### Greenland File
#' Remove PDF page 15 (internal page 130 is duplicate).


filename <- "PCIJ_AB_53_EasternGreenland_DNK_NOR_1933-04-05_ANX_01_NA_NA_BI.pdf"

file.temp <- paste0(filename,
                    "-temp")

file_move(filename,
          file.temp)

pdf_subset(file.temp,
           c(1:14,
             16:49),
           filename)

unlink(file.temp)



#'### Sino-Belgian Treaty File
#' This file should contain only the application to institute proceedings, but also contains the subsequent Order of 8 January 1927. As the Order is already contained in a separate file it will be removed from this one. The result is then listed for splitting with English on odd pages in the following step.

filename <- "PCIJ_A_08_SinoBelgianTreaty_BEL_CHN_1926-11-25_APP_01_NA_NA_BI.pdf"

file.temp <- paste0(filename, "-temp")

file_move(filename, file.temp)

pdf_subset(file.temp,
           1:5,
           filename)

unlink(file.temp)




#'### Silesia Files
#' These two files need to be manually recombined and then split again. The first file is missing the last English page, the second file is missing the first French page.

file.temp <- "combine-temp.pdf"

files.combine <- c("PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-02-05_DEC_01_JO_00_BI.pdf",
                   "PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-03-22_ORD_01_DH_00_BI.pdf")


pdf_combine(files.combine,
            file.temp)


pdf_subset(file.temp,
           c(1, 3, 5),
           "PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-02-05_DEC_01_JO_00_FR.pdf")

pdf_subset(file.temp,
           c(2, 4, 6),
           "PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-02-05_DEC_01_JO_00_EN.pdf")

pdf_subset(file.temp,
           c(5, 7),
           "PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-03-22_ORD_01_DH_00_FR.pdf")

pdf_subset(file.temp,
           c(6, 8),
           "PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-03-22_ORD_01_DH_00_EN.pdf")

unlink(file.temp)



#'### Danzig File
#' French and German alternate in this file, not English and French. Split accordingly.

file <- "PCIJ_B_15_DanzigCourts_LNC_NA_1928-03-03_ANX_02_NA_NA_BI.pdf"

temp1 <- seq(1, pdf_length(file), 1)

even <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) == 0]  
even.name <- gsub("BI\\.pdf",
                  "DE\\.pdf",
                  file) 
pdf_subset(file,
           pages = even,
           output = even.name)

odd <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) != 0]    
odd.name <- gsub("BI\\.pdf",
                 "FR\\.pdf",
                 file)   
pdf_subset(file,
           pages = odd,
           output = odd.name) 




#'## Start Fork Cluster

cl <- makeForkCluster(fullCores)
registerDoParallel(cl)



#'## English on Odd Pages
#' The following files will be split on the assumption that the English version is on odd-numbered pages:
odd.english <- split[split == "odd-english"]$newname

odd.english <- c(odd.english,
                 "PCIJ_A_08_SinoBelgianTreaty_BEL_CHN_1926-11-25_APP_01_NA_NA_BI.pdf")




#'### Number of Files to Split
length(odd.english)

#'### Names of Files to Split
print(odd.english)


#'### Execute Split

out <- foreach(file = odd.english,
               .errorhandling = 'pass',
               .combine = c) %dopar% {
    
    out1 <- vector(mode = "list",
                   length = 2)
    
    temp1 <- seq(1, pdf_length(file), 1)

    
    even <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) == 0]
    even.name <- gsub("BI\\.pdf",
                      "FR\\.pdf",
                      file)
    out1[[1]] <- pdf_subset(file,
                            pages = even,
                            output = even.name)

    
    odd <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) != 0]
    odd.name <- gsub("BI\\.pdf",
                     "EN\\.pdf",
                     file)                 
    out1[[2]] <- pdf_subset(file,
                            pages = odd,
                            output = odd.name)
    
    return(out1)
}

#'### Print Split Results
print(unlist(out))



#'## English on Even Pages
#' The following files will be split on the assumption that the English version is on even-numbered pages:
even.english <- split[split == "even-english"]$newname


#'### Number of Files to Split
length(even.english)

#'### Names of Files to Split
print(even.english)


#'### Execute Split

out <- foreach(file = even.english,
               .errorhandling = 'pass',
               .combine = c) %dopar% {
    
    out1 <- vector(mode = "list",
                   length = 2)
    
    temp1 <- seq(1, pdf_length(file), 1)
    
    even <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) == 0]
    even.name <- gsub("BI\\.pdf",
                      "EN\\.pdf",
                      file)
    out1[[1]] <- pdf_subset(file,
                            pages = even,
                            output = even.name)

    
    odd <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) != 0]
    odd.name <- gsub("BI\\.pdf",
                     "FR\\.pdf",
                     file)
    out1[[2]] <- pdf_subset(file,
                            pages = odd,
                            output = odd.name)
    
    return(out1)
}

#'### Print Split Results
print(unlist(out))


#'## Shutdown Fork Cluster
stopCluster(cl)


#'## Clean up Multilingual Originals
files.pdf.bi <- list.files(pattern = "BI\\.pdf$")

length(files.pdf.bi)

file_move(files.pdf.bi,
          "MULT_PDF_ORIGINAL_FULL")


#'## Copy English and French Originals

file_copy("PCIJ_A_03_Neuilly_BGR_GRC_1924-09-12_ANX_01_NA_NA_EN.pdf",
          "MULT_PDF_ORIGINAL_FULL")

file_copy("PCIJ_A_07_GermanInterestsUpperSilesia_DEU_POL_1926-05-25_ANX_01_NA_NA_FR.pdf",
          "MULT_PDF_ORIGINAL_FULL")

file_copy("PCIJ_AB_70_Meuse_NLD_BEL_1937-06-28_ANX_01_NA_NA_FR.pdf",
          "MULT_PDF_ORIGINAL_FULL")




#'# Detect Missing Counterparts for each Language Variant

files.de <- list.files(pattern = "DE\\.pdf")
files.en <- list.files(pattern = "EN\\.pdf")
files.fr <- list.files(pattern = "FR\\.pdf")


#'## Difference between French and English File Lists
abs(length(files.en) - length(files.fr))


#'## Show Missing French Documents
files.fr.temp <- gsub("FR\\.pdf",
                      "EN\\.pdf",
                      files.fr)

frenchmissing <- setdiff(files.en,
                         files.fr.temp)

frenchmissing <- gsub("EN\\.pdf",
                      "FR\\.pdf",
                      frenchmissing)

print(frenchmissing)


#'## Show Missing English Documents
files.en.temp <- gsub("EN\\.pdf",
                      "FR\\.pdf",
                      files.en)

englishmissing <- setdiff(files.fr,
                          files.en.temp)

englishmissing <- gsub("FR\\.pdf",
                       "EN\\.pdf",
                       englishmissing)

print(englishmissing)



#'## Show German Documents
print(files.de)


#'## Clean up German Originals
#' **Note:** Strictly speaking one of the German documents (the Danzig Courts file) is not a true original, as it was split from a bilingual file. However the quality of the document (scan and OCR) is original, so it is stored with the other originals to avoid creating another variant for a single document.

file_move(files.de,
          "MULT_PDF_ORIGINAL_FULL")






#'# Text Extraction Module


#'## Define Set of Files to Process

files.pdf <- list.files(pattern = "\\.pdf$",
                        ignore.case = TRUE)


#'## Number of Files to Process
length(files.pdf)


#'## Show Function: f.dopar.pagenums
#+ results = "asis"
print(f.dopar.pagenums)


#'## Count Pages
f.dopar.pagenums(files.pdf,
                 sum = TRUE,
                 threads = fullCores)


#'## Show Function: f.dopar.pdfextract
#+ results = "asis"
print(f.dopar.pdfextract)


#'## Extract Text
result <- f.dopar.pdfextract(files.pdf,
                             threads = fullCores)





#'## Move Extracted TXT Files

txt.extracted.en <- list.files(pattern = "EN\\.txt")
txt.extracted.fr <- list.files(pattern = "FR\\.txt")

file_move(txt.extracted.en,
          "EN_TXT_EXTRACTED_FULL")

file_move(txt.extracted.fr,
          "FR_TXT_EXTRACTED_FULL")







#'# Tesseract OCR Module

#'## Show Function: f.dopar.pdfocr
#+ results = "asis"
print(f.dopar.pdfocr)


#+
#'## English

#+
#'### Set of English Documents to Process
files.ocr.en <- list.files(pattern = "EN\\.pdf")

#'### Number of English Documents to Process
length(files.ocr.en)

#'### Number of English Pages to Process
f.dopar.pagenums(files.ocr.en,
                 sum = TRUE,
                 threads = fullCores)


#'### Run OCR on English Documents
#' **Note:** Training data is set to include both English and French. Lengthy quotations in a non-dominant language are common in international law. Order in language setting matters and for English documents "eng" is set as the primary training data.


result <- f.dopar.pdfocr(files.ocr.en,
                         dpi = ocr.dpi,
                         lang = "eng+fra",
                         output = "pdf txt",
                         jobs = ocrCores)





#'## French

#'### Set of French Documents to Process
files.ocr.fr <- list.files(pattern = "FR\\.pdf")

#'### Number of French Documents to Process
length(files.ocr.fr)

#'### Number of French Pages to Process
f.dopar.pagenums(files.ocr.fr,
                 sum = TRUE,
                 threads = fullCores)



#'### Run OCR on French Documents
#' **Note:** Training data is set to include both French and English. Lengthy quotations in a non-dominant language are common in international law. Order in language setting matters and for French documents "fra" is set as the primary training data.

result <- f.dopar.pdfocr(files.ocr.fr,
                         dpi = ocr.dpi,
                         lang = "fra+eng",
                         output = "pdf txt",
                         jobs = ocrCores)







#'## Rename Files

#+ results = "hide"
files.pdf <- list.files(pattern = "\\.pdf$")

files.pdf.enhanced <- gsub("_TESSERACT.pdf",
                           "_ENHANCED.pdf",
                           files.pdf)

file.rename(files.pdf,
            files.pdf.enhanced)


#+ results = "hide"
files.txt <- list.files(pattern = "\\.txt$")

files.txt.new <- gsub("_TESSERACT.txt",
                      ".txt",
                      files.txt)

file.rename(files.txt,
            files.txt.new)




#'## Move TXT files

files.ocr.txt.en <- list.files(pattern = "EN\\.txt")
files.ocr.txt.fr <- list.files(pattern = "FR\\.txt")

file_move(files.ocr.txt.en,
          "EN_TXT_TESSERACT_FULL")

file_move(files.ocr.txt.fr,
          "FR_TXT_TESSERACT_FULL")




#'## Move PDF files

files.ocr.pdf.enhanced.en <- list.files(pattern = "EN_ENHANCED\\.pdf")
files.ocr.pdf.enhanced.fr <- list.files(pattern = "FR_ENHANCED\\.pdf")

files.ocr.pdf.original.en <- list.files(pattern = "EN\\.pdf")
files.ocr.pdf.original.fr <- list.files(pattern = "FR\\.pdf")


file_move(files.ocr.pdf.enhanced.en,
          "EN_PDF_ENHANCED_FULL")

file_move(files.ocr.pdf.enhanced.fr,
          "FR_PDF_ENHANCED_FULL")

file_move(files.ocr.pdf.original.en,
          "EN_PDF_ORIGINALSPLIT_FULL")

file_move(files.ocr.pdf.original.fr,
          "FR_PDF_ORIGINALSPLIT_FULL")






#'# Create Majority-Only Variant

majonly.en <- list.files("EN_PDF_ENHANCED_FULL",
                         pattern ="(JUD|ADV|ORD|DEC)_[0-9]{2}_[A-Z-]+_00_EN_ENHANCED\\.pdf",
                         full.names = TRUE)

majonly.fr <- list.files("FR_PDF_ENHANCED_FULL",
                         pattern ="(JUD|ADV|ORD|DEC)_[0-9]{2}_[A-Z-]+_00_FR_ENHANCED\\.pdf",
                         full.names = TRUE)

file_copy(majonly.en,
          "EN_PDF_ENHANCED_MajorityOpinions")

file_copy(majonly.fr,
          "FR_PDF_ENHANCED_MajorityOpinions")







#'# Read in TXT Files

#'## Define Variable Names

names.variables <- c("court",
                     "series",
                     "seriesno",
                     "shortname",
                     "applicant",
                     "respondent",
                     "date",
                     "doctype",
                     "collision",
                     "stage",
                     "opinion",
                     "language")




#'## TESSERACT Variants

data.tesseract.en <- readtext("EN_TXT_TESSERACT_FULL/*.txt",
                         docvarsfrom = "filenames", 
                         docvarnames = names.variables,
                         dvsep = "_", 
                         encoding = "UTF-8")


data.tesseract.fr <- readtext("FR_TXT_TESSERACT_FULL/*.txt",
                         docvarsfrom = "filenames", 
                         docvarnames = names.variables,
                         dvsep = "_", 
                         encoding = "UTF-8")


#'## EXTRACTED Variants

data.extracted.en <- readtext("EN_TXT_EXTRACTED_FULL/*.txt",
                              docvarsfrom = "filenames", 
                              docvarnames = names.variables,
                              dvsep = "_", 
                              encoding = "UTF-8")


data.extracted.fr <- readtext("FR_TXT_EXTRACTED_FULL/*.txt",
                              docvarsfrom = "filenames", 
                              docvarnames = names.variables,
                              dvsep = "_", 
                              encoding = "UTF-8")


#'## Convert to Data Table

setDT(data.tesseract.en)
setDT(data.tesseract.fr)
setDT(data.extracted.en)
setDT(data.extracted.fr)


#'# Clean Texts


#+
#'## Remove Hyphenation across Linebreaks
#' Hyphenation across linebreaks is a serious issue for longer texts. Such hyphenated words are often not recognized as a single token by standard tokenization. The result is two unique and non-expressive tokens instead of a single, expressive token. This section removes these hyphenations.

#+
#'### Show Function: f.hyphen.remove

print(f.hyphen.remove)

#'### Execute Function

data.tesseract.en[, text := lapply(.(text), f.hyphen.remove)]
data.tesseract.fr[, text := lapply(.(text), f.hyphen.remove)]

data.extracted.en[, text := lapply(.(text), f.hyphen.remove)]
data.extracted.fr[, text := lapply(.(text), f.hyphen.remove)]


#'## Replace Special Characters
#' This section replaces special characters with their closest equivalents in the Latin alphabet, as some R functions have difficulties processing the originals. These characters usually occur due to OCR mistakes.

#+
#'### Show Function: f.special.replace

print(f.special.replace)

#'### Execute Function

data.tesseract.en[, text := lapply(.(text), f.special.replace)]
data.tesseract.fr[, text := lapply(.(text), f.special.replace)]

data.extracted.en[, text := lapply(.(text), f.special.replace)]
data.extracted.fr[, text := lapply(.(text), f.special.replace)]




#'# OCR Quality Control Module
#' This module measures the quality of the new Tesseract-generated OCR text against the OCR text provided by the ICJ, which was extracted from the original documents.

#+
#'## Create Corpora

corpus.en.b <- corpus(data.tesseract.en)
corpus.en.e <- corpus(data.extracted.en)

corpus.fr.b <- corpus(data.tesseract.fr)
corpus.fr.e <- corpus(data.extracted.fr)


#'## Show Function: f.token.processor

print(f.token.processor)


#'## Tokenize

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

tokens.en.b <- f.token.processor(corpus.en.b)
tokens.en.e <- f.token.processor(corpus.en.e)


quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

tokens.fr.b <- f.token.processor(corpus.fr.b)
tokens.fr.e <- f.token.processor(corpus.fr.e)




#'## Create Document-Feature-Matrices

dfm.en.b <- dfm(tokens.en.b)
dfm.en.e <- dfm(tokens.en.e)

dfm.fr.b <- dfm(tokens.fr.b)
dfm.fr.e <- dfm(tokens.fr.e)


#'## Number of Features TESSERACT

#+
#'### English
nfeat(dfm.en.b)

#+
#'### French
nfeat(dfm.fr.b)


#'## Number of Features EXTRACTED

#+
#'### English
nfeat(dfm.en.e)

#+
#'### French
nfeat(dfm.fr.e)


#'## Features Reduction
#' **Note:** This is the number of features which have been saved by using advanced OCR in comparison to the OCR used by the ICJ.

#+
#'### English

#' **Absolute Reduction**
nfeat(dfm.en.e)- nfeat(dfm.en.b)

#' **Relative Reduction in Percent**
(1 - (nfeat(dfm.en.b) / nfeat(dfm.en.e))) * 100



#'### French

#' **Absolute Reduction**
nfeat(dfm.fr.e)- nfeat(dfm.fr.b)

#' **Relative Reduction in Percent**
(1 - (nfeat(dfm.fr.b) / nfeat(dfm.fr.e))) * 100









#'# Language Purity Module
#' This module automatically analyzes the n-gram patterns of each document with **textcat** to detect the most likely language. Only English and French are considered. This is to ensure maximum monolinguality of documents, which is an advantage in Natural Language Processing.


#+
#'## Limit Detection to English and French

lang.profiles <- TC_byte_profiles[names(TC_byte_profiles) %in% c("english",
                                                                 "french")]

#'## Automatic Language Detection

data.tesseract.en$textcat <- textcat(data.tesseract.en$text,
                                     p = lang.profiles)

data.tesseract.fr$textcat <- textcat(data.tesseract.fr$text,
                                     p = lang.profiles)


#'## Detected Languages

#'### Should only read 'english'
unique(data.tesseract.en$textcat)

#'### Should only read 'french'
unique(data.tesseract.fr$textcat)



#'## Show Mismatches
#' Print names of files which failed to match the language specified in metadata.

langtest.fail.en <- data.tesseract.en[textcat != "english", .(doc_id, textcat)]
print(langtest.fail.en)

langtest.fail.fr <- data.tesseract.fr[textcat != "french", .(doc_id, textcat)]
print(langtest.fail.fr)


#'## Final Note: Human Review of Mismatches
#' All documents flagged by textcat were reviewed and appropriate remedies devised. Documents falsely flagged as "catalan" were correctly labelled when possible languages were limited to English and French. Some documents received customized split instructions after being flagged.






#+
#'# Add and Delete Variables


#+
#'## Delete Textcat Classifications

data.tesseract.en$textcat <- NULL
data.tesseract.fr$textcat <- NULL


#'## Add Variable "year"

data.tesseract.en$year <- year(data.tesseract.en$date)
data.tesseract.fr$year <- year(data.tesseract.fr$date)


#'## Add Variable "minority"
#' "0" indicates a majority opinion, "1" a minority opinion.

data.tesseract.en$minority <- (data.tesseract.en$opinion != 0) * 1
data.tesseract.fr$minority <- (data.tesseract.fr$opinion != 0) * 1



#'## Add Variable "fullname"



#+
#'### Read Hand Coded Data
casenames <- fread("data/CD-PCIJ_Source_Filenames-FullNames-SplitInstructions.csv",
                   header = TRUE)


#'### Create Variable

data.tesseract.en$fullname <- casenames$casename[match(data.tesseract.en$doc_id,
                                                       gsub("(BI|FR|EN)\\.pdf",
                                                            "EN\\.txt",
                                                            casenames$newname))]

data.tesseract.fr$fullname <- casenames$casename[match(data.tesseract.fr$doc_id,
                                                       gsub("(BI|FR|EN)\\.pdf",
                                                            "FR\\.txt",
                                                            casenames$newname))]




#'## Add Variable "caseno"
#' The "caseno" variable is constructed by joining the "series" and "seriesno" variables, e.g. "AB" and "41" become "AB41". This is intended to be used as a unique case identifier similar to the "caseno" variable in the CD-PCIJ, though there are limitations to this approach, as quite a few cases span multiple combined numbers.

data.tesseract.en$caseno <- paste0(data.tesseract.en$series,
                                   data.tesseract.en$seriesno)

data.tesseract.fr$caseno <- paste0(data.tesseract.fr$series,
                                   data.tesseract.fr$seriesno)



#'## Add Variable "applicant_region"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-PCIJ_Source_CountryCodes.csv")


#'### Merge Regions for English Version

applicant_region <- data.tesseract.en$applicant

applicant_region <- gsub("LNC",
                         "NA",
                         applicant_region)

applicant_region <- gsub("-",
                         "|",
                         applicant_region)


applicant_region <- mgsub(applicant_region,
                          countrycodes$ISO3,
                          countrycodes$region)

data.tesseract.en$applicant_region <- applicant_region



#'### Merge Regions for French Version

applicant_region <- data.tesseract.fr$applicant

applicant_region <- gsub("LNC",
                         "NA",
                         applicant_region)

applicant_region <- gsub("-",
                         "|",
                         applicant_region)


applicant_region <- mgsub(applicant_region,
                          countrycodes$ISO3,
                          countrycodes$region)

data.tesseract.fr$applicant_region <- applicant_region



#'## Add Variable "respondent_region"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-PCIJ_Source_CountryCodes.csv")


#'### Merge Regions for English Version

respondent_region <- data.tesseract.en$respondent

respondent_region <- gsub("-",
                          "|",
                          respondent_region)

respondent_region <- mgsub(respondent_region,
                           countrycodes$ISO3,
                           countrycodes$region)

data.tesseract.en$respondent_region <- respondent_region



#'### Merge Regions for French Version


respondent_region <- data.tesseract.fr$respondent

respondent_region <- gsub("-",
                          "|",
                          respondent_region)

respondent_region <- mgsub(respondent_region,
                           countrycodes$ISO3,
                           countrycodes$region)

data.tesseract.fr$respondent_region <- respondent_region





#'## Add Variable "applicant_subregion"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-PCIJ_Source_CountryCodes.csv")


#'### Merge Subregions for English Version

applicant_subregion <- data.tesseract.en$applicant

applicant_subregion <- gsub("LNC",
                            "NA",
                            applicant_subregion)

applicant_subregion <- gsub("-",
                            "|",
                            applicant_subregion)


applicant_subregion <- mgsub(applicant_subregion,
                             countrycodes$ISO3,
                             countrycodes$subregion)

data.tesseract.en$applicant_subregion <- applicant_subregion



#'### Merge Subregions for French Version

applicant_subregion <- data.tesseract.fr$applicant

applicant_subregion <- gsub("LNC",
                            "NA",
                            applicant_subregion)

applicant_subregion <- gsub("-",
                            "|",
                            applicant_subregion)


applicant_subregion <- mgsub(applicant_subregion,
                             countrycodes$ISO3,
                             countrycodes$subregion)

data.tesseract.fr$applicant_subregion <- applicant_subregion



#'## Add Variable "respondent_subregion"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-PCIJ_Source_CountryCodes.csv")


#'### Merge Subregions for English Version

respondent_subregion <- data.tesseract.en$respondent

respondent_subregion <- gsub("-",
                         "|",
                         respondent_subregion)

respondent_subregion <- mgsub(respondent_subregion,
                          countrycodes$ISO3,
                          countrycodes$subregion)

data.tesseract.en$respondent_subregion <- respondent_subregion



#'### Merge Subregions for French Version


respondent_subregion <- data.tesseract.fr$respondent

respondent_subregion <- gsub("-",
                             "|",
                             respondent_subregion)

respondent_subregion <- mgsub(respondent_subregion,
                              countrycodes$ISO3,
                              countrycodes$subregion)

data.tesseract.fr$respondent_subregion <- respondent_subregion






#'## Add Variable "doi_concept"

data.tesseract.en$doi_concept <- rep(doi.concept,
                                     data.tesseract.en[,.N])

data.tesseract.fr$doi_concept <- rep(doi.concept,
                                     data.tesseract.fr[,.N])

#'## Add Variable "doi_version"

data.tesseract.en$doi_version <- rep(doi.version,
                                     data.tesseract.en[,.N])

data.tesseract.fr$doi_version <- rep(doi.version,
                                     data.tesseract.fr[,.N])

#'## Add Variable "version"

data.tesseract.en$version <- as.character(rep(version,
                                              data.tesseract.en[,.N]))

data.tesseract.fr$version <- as.character(rep(version,
                                              data.tesseract.fr[,.N]))



#'## Add Variable "license"

data.tesseract.en$license <- as.character(rep(license,
                                         data.tesseract.en[,.N]))

data.tesseract.fr$license <- as.character(rep(license,
                                         data.tesseract.fr[,.N]))




#'# Frequency Tables
#' Frequency tables are a very useful tool for checking the plausibility of categorical variables and detecting anomalies in the data. This section will calculate frequency tables for all variables of interest.



#+
#'## Show Function: f.fast.freqtable

#+ results = "asis"
print(f.fast.freqtable)


#+
#'## English Corpus

#+
#'### Variables to Ignore
print(freq.var.ignore)


#'### Variables to Analyze
varlist <- names(data.tesseract.en)

varlist <- setdiff(varlist,
                   freq.var.ignore)

print(varlist)


#'### Construct Frequency Tables

prefix <- paste0(datashort,
                 "_EN_01_FrequencyTable_var-")


#+ results = "asis"
f.fast.freqtable(data.tesseract.en,
                 varlist = varlist,
                 sumrow = TRUE,
                 output.list = FALSE,
                 output.kable = TRUE,
                 output.csv = TRUE,
                 outputdir = outputdir,
                 prefix = prefix,
                 align = c("p{5cm}",
                           rep("r", 4)))





#'\newpage
#'## French Corpus

#+
#'### Variables to Ignore
print(freq.var.ignore)

#'### Variables to Analyze
varlist <- names(data.tesseract.en)

varlist <- setdiff(varlist,
                   freq.var.ignore)

print(varlist)



#'### Construct Frequency Tables

prefix <- paste0(datashort,
                 "_FR_01_FrequencyTable_var-")


#+ results = "asis"
f.fast.freqtable(data.tesseract.fr,
                 varlist = varlist,
                 sumrow = TRUE,
                 output.list = FALSE,
                 output.kable = TRUE,
                 output.csv = TRUE,
                 outputdir = outputdir,
                 prefix = prefix,
                 align = c("p{5cm}",
                           rep("r", 4)))





#'# Visualize Frequency Tables

#+
#'## Load Tables

prefix.en <- paste0("ANALYSIS/",
                    datashort,
                    "_EN_01_FrequencyTable_var-")

prefix.fr <- paste0("ANALYSIS/",
                    datashort,
                    "_FR_01_FrequencyTable_var-")

table.en.doctype <- fread(paste0(prefix.en,
                                 "doctype.csv"))

table.en.opinion <- fread(paste0(prefix.en,
                                 "opinion.csv"))

table.en.year <- fread(paste0(prefix.en,
                              "year.csv"))

table.fr.doctype <- fread(paste0(prefix.fr,
                                 "doctype.csv"))

table.fr.opinion <- fread(paste0(prefix.fr,
                                 "opinion.csv"))

table.fr.year <- fread(paste0(prefix.fr,
                              "year.csv"))





#'\newpage
#'## Doctype

#+
#'### English

freqtable <- table.en.doctype[-.N]


#+ CD-PCIJ_EN_02_Barplot_Doctype, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(doctype,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black",
             width = 0.4) +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Documents per Document Type"),
        caption = paste("DOI:",
                        doi.version),
        x = "Document Type",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#'### French

freqtable <- table.fr.doctype[-.N]


#+ CD-PCIJ_FR_02_Barplot_Doctype, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(doctype,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black",
             width = 0.4) +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Documents per Document Type"),
        caption = paste("DOI:",
                        doi.version),
        x = "Document Type",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )


#'\newpage
#'## Opinion

#+
#'### English

freqtable <- table.en.opinion[-.N]

#+ CD-PCIJ_EN_03_Barplot_Opinion, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(opinion,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Documents per Opinion Number"),
        caption = paste("DOI:",
                        doi.version),
        x = "Opinion Number",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#'### French

freqtable <- table.fr.opinion[-.N]

#+ CD-PCIJ_FR_03_Barplot_Opinion, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(opinion,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Documents per Opinion Number"),
        caption = paste("DOI:",
                        doi.version),
        x = "Opinion Number",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#'## Year

#+
#'### English

freqtable <- table.en.year[-.N][,lapply(.SD, as.numeric)]

#+ CD-PCIJ_EN_04_Barplot_Year, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = year,
                 y = N),
             stat = "identity",
             fill = "black") +
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Documents per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 16),
        plot.title = element_text(size = 16,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )


#'\newpage
#'### French

freqtable <- table.fr.year[-.N][,lapply(.SD, as.numeric)]

#+ CD-PCIJ_FR_04_Barplot_Year, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = year,
                 y = N),
             stat = "identity",
             fill = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Documents per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 16),
        plot.title = element_text(size = 16,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )








#'# Summary Statistics

#+
#'## Linguistic Metrics
#' For the text of each document the number of characters, tokens, types and sentences will be calculated.



#+
#'### Show Function: f.lingsummarize.iterator

#+ results = "asis"
print(f.lingsummarize.iterator)



#'### Calculate Linguistic Metrics

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

summary.corpus.en <- f.lingsummarize.iterator(data.tesseract.en,
                                          threads = fullCores,
                                          chunksize = 1)


quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

summary.corpus.fr <- f.lingsummarize.iterator(data.tesseract.fr,
                                          threads = fullCores,
                                          chunksize = 1)


#'### Add Linguistic Metrics to Full Corpora

data.tesseract.en <- cbind(data.tesseract.en,
                      summary.corpus.en)

data.tesseract.fr <- cbind(data.tesseract.fr,
                      summary.corpus.fr)


#'### Create Metadata-only Variants

meta.tesseract.en <- data.tesseract.en[, !"text"]
meta.tesseract.fr <- data.tesseract.fr[, !"text"]




#+
#'### Calculate Summaries: English

dt.summary.ling <- meta.tesseract.en[, lapply(.SD,
                                              function(x)unclass(summary(x))),
                                     .SDcols = c("nchars",
                                                 "ntokens",
                                                 "ntypes",
                                                 "nsentences")]


dt.sums.ling <- meta.tesseract.en[,
                                  lapply(.SD, sum),
                                  .SDcols = c("nchars",
                                              "ntokens",
                                              "ntypes",
                                              "nsentences")]

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

tokens.temp <- tokens(corpus(data.tesseract.en),
                      what = "word",
                      remove_punct = FALSE,
                      remove_symbols = FALSE,
                      remove_numbers = FALSE,
                      remove_url = FALSE,
                      remove_separators = TRUE,
                      split_hyphens = FALSE,
                      include_docvars = FALSE,
                      padding = FALSE
                      )

dt.sums.ling$ntypes <- nfeat(dfm(tokens.temp))




dt.stats.ling <- rbind(dt.sums.ling,
                       dt.summary.ling)

dt.stats.ling <- transpose(dt.stats.ling,
                           keep.names = "names")

setnames(dt.stats.ling, c("Variable",
                          "Total",
                          "Min",
                          "Quart1",
                          "Median",
                          "Mean",
                          "Quart3",
                          "Max"))

#'\newpage
#'### Show Summaries: English

kable(dt.stats.ling,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE)


#'### Write Summaries to Disk: English

fwrite(dt.stats.ling,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Linguistic.csv"),
       na = "NA")






#'\newpage
#'### Calculate Summaries: French

dt.summary.ling <- meta.tesseract.fr[, lapply(.SD,
                                              function(x)unclass(summary(x))),
                                     .SDcols = c("nchars",
                                                 "ntokens",
                                                 "ntypes",
                                                 "nsentences")]


dt.sums.ling <- meta.tesseract.fr[,
                                  lapply(.SD, sum),
                                  .SDcols = c("nchars",
                                              "ntokens",
                                              "ntypes",
                                              "nsentences")]


quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

tokens.temp <- tokens(corpus(data.tesseract.fr),
                      what = "word",
                      remove_punct = FALSE,
                      remove_symbols = FALSE,
                      remove_numbers = FALSE,
                      remove_url = FALSE,
                      remove_separators = TRUE,
                      split_hyphens = FALSE,
                      include_docvars = FALSE,
                      padding = FALSE
                      )

dt.sums.ling$ntypes <- nfeat(dfm(tokens.temp))




dt.stats.ling <- rbind(dt.sums.ling,
                       dt.summary.ling)

dt.stats.ling <- transpose(dt.stats.ling,
                           keep.names = "names")

setnames(dt.stats.ling, c("Variable",
                          "Total",
                          "Min",
                          "Quart1",
                          "Median",
                          "Mean",
                          "Quart3",
                          "Max"))


#'\newpage
#'### Show Summaries: French

kable(dt.stats.ling,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE)


#'### Write Summaries to Disk: French

fwrite(dt.stats.ling,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Linguistic.csv"),
       na = "NA")













#'\newpage
#'## Distributions

#+
#'### Tokens per Year: English

tokens.year.en <- meta.tesseract.en[,
                                    sum(ntokens),
                                    by = "year"]



#+ CD-PCIJ_EN_05_TokensPerYear, fig.height = 6, fig.width = 9
print(
    ggplot(data = tokens.year.en,
           aes(x = year,
               y = V1))+
    geom_bar(stat = "identity",
             fill = "black")+
    scale_y_continuous(labels = comma)+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Number of Tokens per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Tokens"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold")
    )
)



#'\newpage
#'### Tokens per Year: French

tokens.year.fr <- meta.tesseract.fr[,
                                    sum(ntokens),
                                    by = "year"]

#+ CD-PCIJ_FR_05_TokensPerYear, fig.height = 6, fig.width = 9
print(
    ggplot(data = tokens.year.fr,
           aes(x = year,
               y = V1))+
    geom_bar(stat = "identity",
             fill = "black")+
    scale_y_continuous(labels = comma)+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Number of Tokens per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Tokens"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold")
    )
)





#'\newpage
#+
#'### Density: Characters

#+ CD-PCIJ_EN_06_Density_Characters, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.en) +
    geom_density(aes(x = nchars),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distribution of Document Length (Characters)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Characters",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-PCIJ_FR_06_Density_Characters, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.fr) +
    geom_density(aes(x = nchars),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distribution of Document Length (Characters)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Characters",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )







#'\newpage
#'### Density: Tokens

#+ CD-PCIJ_EN_07_Density_Tokens, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.en) +
    geom_density(aes(x = ntokens),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distribution of Document Length (Tokens)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Tokens",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-PCIJ_FR_07_Density_Tokens, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.fr) +
    geom_density(aes(x = ntokens),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distribution of Document Length (Tokens)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Tokens",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )





#'\newpage
#'### Density: Types

#+ CD-PCIJ_EN_08_Density_Types, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.en) +
    geom_density(aes(x = ntypes),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distribution of Document Length (Types)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Types",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )





#'\newpage
#+ CD-PCIJ_FR_08_Density_Types, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.fr) +
    geom_density(aes(x = ntypes),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distribution of Document Length (Types)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Types",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#'### Density: Sentences

#+ CD-PCIJ_EN_09_Density_Sentences, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.en) +
    geom_density(aes(x = nsentences),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distribution of Document Length (Sentences)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Sentences",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-PCIJ_FR_09_Density_Sentences, fig.height = 6, fig.width = 9
ggplot(data = meta.tesseract.fr) +
    geom_density(aes(x = nsentences),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distribution of Document Length (Sentences)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Sentences",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#'### All Distributions of Linguistic Metrics
#' When plotting a boxplot on a logarithmic scale the standard geom_boxplot() function from ggplot2 incorrectly performs the statistical transformation first before calculating the boxplot statistics. While median and quartiles are based on ordinal position the inter-quartile range differs depending on when statistical transformation is performed.
#'
#' Solutions are based on this SO question: https://stackoverflow.com/questions/38753628/ggplot-boxplot-length-of-whiskers-with-logarithmic-axis

print(f.boxplot.body)
print(f.boxplot.outliers)


dt.allmetrics.en <- melt(summary.corpus.en,
                         measure.vars = rev(c("nchars",
                                              "ntokens",
                                              "ntypes",
                                              "nsentences")))


#'\newpage
#+ CD-PCIJ_EN_10_Distributions_LinguisticMetrics, fig.height = 10, fig.width = 8.3
ggplot(dt.allmetrics.en, aes(x = value,
                             y = variable,
                             fill = variable)) +
    geom_violin()+
    stat_summary(fun.data = f.boxplot.body,
                 geom = "errorbar",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.body,
                 geom = "boxplot",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.outliers,
                 geom = "point",
                 size =  0.5,
                 alpha = 0.2)+
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    scale_y_discrete(labels = rev(c("Characters",
                                    "Tokens",
                                    "Types",
                                    "Sentences")))+
    theme_bw() +
    scale_fill_viridis_d(begin = 0.35)+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distributions of Document Length"),
        caption = paste("DOI:",
                        doi.version),
        x = "Value",
        y = "Linguistic Metric"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage

dt.allmetrics.fr <- melt(summary.corpus.fr,
                         measure.vars = rev(c("nchars",
                                              "ntokens",
                                              "ntypes",
                                              "nsentences")))

#+ CD-PCIJ_FR_10_Distributions_LinguisticMetrics, fig.height = 10, fig.width = 8.3
ggplot(dt.allmetrics.fr, aes(x = value,
                             y = variable,
                             fill = variable)) +
    geom_violin()+
    stat_summary(fun.data = f.boxplot.body,
                 geom = "errorbar",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.body,
                 geom = "boxplot",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.outliers,
                 geom = "point",
                 size =  0.5,
                 alpha = 0.2)+
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    scale_y_discrete(labels = rev(c("Characters",
                                    "Tokens",
                                    "Types",
                                    "Sentences")))+
    theme_bw() +
    scale_fill_viridis_d(begin = 0.35)+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distributions of Document Length"),
        caption = paste("DOI:",
                        doi.version),
        x = "Value",
        y = "Linguistic Metric"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )









#'\newpage
#'## Number of Majority Opinions

#+
#'### English

dt.maj.disaggregated <- meta.tesseract.en[opinion == 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.maj.disaggregated$N))

dt.maj.disaggregated <- rbind(dt.maj.disaggregated,
                              sumrow,
                              use.names = FALSE)



kable(dt.maj.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.maj.disaggregated,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Majority.csv"),
       na = "NA")



#'\newpage
#'### French

dt.maj.disaggregated <- meta.tesseract.fr[opinion == 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.maj.disaggregated$N))

dt.maj.disaggregated <- rbind(dt.maj.disaggregated,
                              sumrow,
                              use.names=FALSE)


kable(dt.maj.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.maj.disaggregated,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Majority.csv"),
       na = "NA")






#'\newpage
#'## Number of Minority Opinions

#+
#'### English

dt.min.disaggregated <- meta.tesseract.en[opinion > 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.min.disaggregated$N))

dt.min.disaggregated <- rbind(dt.min.disaggregated,
                              sumrow,
                              use.names = FALSE)



kable(dt.min.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.min.disaggregated,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Minority.csv"),
       na = "NA")




#'\newpage
#'### French

dt.min.disaggregated <- meta.tesseract.fr[opinion > 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.min.disaggregated$N))

dt.min.disaggregated <- rbind(dt.min.disaggregated,
                              sumrow,
                              use.names = FALSE)


kable(dt.min.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.min.disaggregated,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Minority.csv"),
       na = "NA")




#'## Year Range

summary(meta.tesseract.en$year) # English
summary(meta.tesseract.fr$year) # French


#'## Date Range

meta.tesseract.en$date <- as.Date(meta.tesseract.en$date)
meta.tesseract.fr$date <- as.Date(meta.tesseract.fr$date)

summary(meta.tesseract.en$date) # English
summary(meta.tesseract.fr$date) # French





#'# Test and Sort Variable Names

#+
#'## Semantic Sorting of Variable Names
#' This step ensures that all variable names documented in the Codebook are present in the data set and sorted according to the order in the Codebook. Where variables are missing in the data or undocumented variables are present this step will throw an error. 

#+
#'### Sort Variables: Full Data Set


setcolorder(data.tesseract.en, # English
            c("doc_id",
              "text",
              "court",
              "series",
              "seriesno", 
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage

setcolorder(data.tesseract.fr, # French
            c("doc_id",
              "text",
              "court",
              "series",
              "seriesno", 
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage
#+
#'### Sort Variables: Metadata

setcolorder(meta.tesseract.en, # English
            c("doc_id",
              "court",
              "series",
              "seriesno", 
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage

setcolorder(meta.tesseract.fr, # French
            c("doc_id",
              "court",
              "series",
              "seriesno", 
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))






#'\newpage
#'## Number of Variables: Full Data Set

length(data.tesseract.en) # English
length(data.tesseract.fr) # French

#'## Number of Variables: Metadata

length(meta.tesseract.en) # English
length(meta.tesseract.fr) # French


#'## List All Variables: Full Data Set
#' "doc_id" is the filename, "text" is the extracted plaintext, third variable onwards are the metadata variables ("docvars").

names(data.tesseract.en) # English
names(data.tesseract.fr) # French


#'## List All Variables: Metadata

names(meta.tesseract.en) # English
names(meta.tesseract.fr) # French








#'# Calculate Detailed Token Frequencies


#+
#'## Create Corpora
corpus.en.b <- corpus(data.tesseract.en)
corpus.fr.b <- corpus(data.tesseract.fr)


#'## Process Tokens


quanteda_options(tokens_locale = "en") # Set Locale for Tokenization
tokens.en <- f.token.processor(corpus.en.b)

quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization
tokens.fr <- f.token.processor(corpus.fr.b)




#'## Construct Document-Feature-Matrices
 
dfm.en <- dfm(tokens.en)
dfm.fr <- dfm(tokens.fr)

dfm.tfidf.en <- dfm_tfidf(dfm.en)
dfm.tfidf.fr <- dfm_tfidf(dfm.fr)




#'## Most Frequent Tokens | TF Weighting | Tables

#+
#'### English

tstat.en <- textstat_frequency(dfm.en,
                               n = 100)

fwrite(tstat.en, paste0(outputdir,
                        datashort,
                        "_EN_11_Top100Tokens_TF-Weighting.csv"))

kable(tstat.en,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Frequency",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")




#'### French

tstat.fr <- textstat_frequency(dfm.fr,
                               n = 100)

fwrite(tstat.fr, paste0(outputdir,
                        datashort,
                        "_FR_11_Top100Tokens_TF-Weighting.csv"))

kable(tstat.fr,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Frequency",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")





#'## Most Frequent Tokens | TFIDF Weighting | Tables

#+
#'### English

tstat.tfidf.en <- textstat_frequency(dfm.tfidf.en,
                                     n = 100,
                                     force = TRUE)

fwrite(tstat.en, paste0(outputdir,
                        datashort,
                        "_EN_12_Top100Tokens_TFIDF-Weighting.csv"))

kable(tstat.tfidf.en,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Weight",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")



#'### French

tstat.tfidf.fr <- textstat_frequency(dfm.tfidf.fr,
                                     n = 100,
                                     force = TRUE)

fwrite(tstat.fr, paste0(outputdir,
                        datashort,
                        "_FR_12_Top100Tokens_TFIDF-Weighting.csv"))

kable(tstat.tfidf.fr,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Weight",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")




#'\newpage
#'## Most Frequent Tokens | TF Weighting | Scatterplots

#+
#'### English


#+ CD-PCIJ_EN_13_Top50Tokens_TF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.en[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Top 50 Tokens | Term Frequency"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Frequency"
    )+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)



#'\newpage
#+
#'### French

#+ CD-PCIJ_FR_13_Top50Tokens_TF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.fr[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Top 50 Tokens | Term Frequency"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Frequency"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)



#'\newpage
#'## Most Frequent Tokens | TFIDF Weighting | Scatterplots

#+
#'### English

#+ CD-PCIJ_EN_14_Top50Tokens_TFIDF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.tfidf.en[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Top 50 Tokens | TF-IDF"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Weight"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)




#'\newpage
#+
#'### French

#+ CD-PCIJ_FR_14_Top50Tokens_TFIDF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.tfidf.fr[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency)) +
    geom_point() +
    coord_flip() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Top 50 Tokens | TF-IDF"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Weight"
    )+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)





#'\newpage
#'## Most Frequent Tokens | TF Weighting | Wordclouds

#+
#'### English

#+ CD-PCIJ_EN_15_Top100Tokens_TF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.en,
                   max_words = 100,
                   min_size = 1,
                   max_size = 5,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))

#'\newpage
#+
#'### French


#+ CD-PCIJ_FR_15_Top100Tokens_TF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.fr,
                   max_words = 100,
                   min_size = 1,
                   max_size = 5,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))


#'\newpage
#'## Most Frequent Tokens | TFIDF Weighting | Wordclouds


#+
#'### English

#+ CD-PCIJ_EN_16_Top100Tokens_TFIDF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.tfidf.en,
                   max_words = 100,
                   min_size = 1,
                   max_size = 2,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))

#'\newpage
#+
#'### French


#+ CD-PCIJ_FR_16_Top100Tokens_TFIDF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.tfidf.fr,
                   max_words = 100,
                   min_size = 1,
                   max_size = 2,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))








#'# Document Similarity
#' This analysis computes the correlation similarity for all documents in each corpus, plots the number of documents to drop as a function of the correlation similarity threshold and outputs the document IDs for specific threshold values.
#'
#' The similarity test uses the standard pre-processed unigram document-feature matrix created by the f.token.processor function for the analyses of detailed token frequencies, i.e. it includes removal of numbers, special characters, stopwords (English/French) and lowercasing. I investigated other pre-processing workflows without the removal of features or lowercasing, as well as bigrams and trigrams, but, based on a qualitative assessment of the results, these performed no better or even worse than the standard workflow. Further research will be required to provide a definitive recommendation on how to deduplicate the corpus.
#'
#' I intentionally do not correct for length, as the analysis focuses on detecting duplicates and near-duplicates, not topical similarity.

#+
#'## Set Ranges
#'
#' **Note:** These ranges should cover most use cases.

threshold.range <- seq(0.8, 1, 0.005)

threshold.N <- length(threshold.range)

print(threshold.range)


print.range <- print.range <- seq(0.8, 0.99, 0.01)

print(print.range)

#'\newpage
#+
#'## English

#+
#'### Calculate Similarity

sim <- textstat_simil(dfm.en,
                      margin = "documents",
                      method = "correlation")

sim.dt <- as.data.table(sim)



#'### Create Empty Lists

list.ndrop <- vector("list",
                    threshold.N)

list.drop.ids <- vector("list",
                       threshold.N)

list.pair.ids <- vector("list",
                        threshold.N)


#'### Build Tables

for (i in 1:threshold.N){
    
    threshold <- threshold.range[i]
    
    pair.ids <- sim.dt[correlation > threshold]
    
    list.pair.ids[[i]] <- pair.ids
    
    drop.ids <- sim.dt[correlation > threshold,
                       .(unique(document1))][order(V1)]
    
    list.drop.ids[[i]] <- drop.ids
    
    ndrop <- drop.ids[,.N]
    
    list.ndrop[[i]] <- data.table(threshold,
                                  ndrop)
    
}


dt.ndrop <- rbindlist(list.ndrop)



#'### IDs of Paired Documents Above Threshold
#' IDs of document pairs, with one of them to drop, as function of correlation similarity.

for (i in print.range){
   
    index <- match(i, threshold.range)
    
    fwrite(list.pair.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_EN_17_DocumentSimilarity_Correlation_PairedDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}



#'### IDs of Duplicate Documents  per Threshold
#' IDs of Documents to drop as function of correlation similarity.

for (i in print.range){
    
    index <- match(i, threshold.range)
    
    fwrite(list.drop.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_EN_17_DocumentSimilarity_Correlation_DuplicateDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}



#'### Count of Duplicate Documents per Threshold
#' Number of Documents to drop as function of correlation similarity

kable(dt.ndrop,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Threshold",
                    "Number to Drop")) %>% kable_styling(latex_options = "repeat_header")

fwrite(dt.ndrop,
       paste0(outputdir,
              datashort,
              "_EN_18_DocumentSimilarity_Correlation_Table.csv"))




#'\newpage
#+ CD-PCIJ_EN_19_DocumentSimilarity_Correlation, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.ndrop,
           aes(x = threshold,
               y = ndrop))+
    geom_line()+
    geom_point()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Document Similarity (Correlation)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Correlation Similarity Threshold",
        y = "Number of Documents Above Threshold"
    )+
    scale_x_continuous(breaks = seq(0.8, 1, 0.02))+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "bottom",
        legend.direction = "vertical"
    )
)





#'\newpage
#'## French


#'### Calculate Similarity

sim <- textstat_simil(dfm.fr,
                      margin = "documents",
                      method = "correlation")

sim.dt <- as.data.table(sim)



#'### Create Empty Lists

list.ndrop <- vector("list",
                     threshold.N)

list.drop.ids <- vector("list",
                        threshold.N)

list.pair.ids <- vector("list",
                        threshold.N)


#'### Build Tables

for (i in 1:threshold.N){
    
    threshold <- threshold.range[i]

    pair.ids <- sim.dt[correlation > threshold]
    
    list.pair.ids[[i]] <- pair.ids
    
    drop.ids <- sim.dt[correlation > threshold,
                       .(unique(document1))][order(V1)]
    
    list.drop.ids[[i]] <- drop.ids
    
    ndrop <- drop.ids[,.N]
    
    list.ndrop[[i]] <- data.table(threshold,
                                  ndrop)
    
}

dt.ndrop <- rbindlist(list.ndrop)


#'### IDs of Paired Documents Above Threshold
#' IDs of document pairs, with one of them to drop, as function of correlation similarity.

for (i in print.range){
   
    index <- match(i, threshold.range)
    
    fwrite(list.pair.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_FR_17_DocumentSimilarity_Correlation_PairedDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}


#'### IDs of Duplicate Documents per Threshold
#' IDs of Documents to drop as function of correlation similarity.

for (i in print.range){

    index <- match(i, threshold.range)
    
    fwrite(list.drop.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_FR_17_DocumentSimilarity_Correlation_DuplicateDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))

}




#'### Count of Duplicate Documents per Threshold
#' Number of Documents to drop as function of correlation similarity.

kable(dt.ndrop,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Threshold",
                    "Number to Drop")) %>% kable_styling(latex_options = "repeat_header")

fwrite(dt.ndrop,
       paste0(outputdir,
              datashort,
              "_FR_18_DocumentSimilarity_Correlation_Table.csv"))



#'\newpage
#+ CD-PCIJ_FR_19_DocumentSimilarity_Correlation, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.ndrop,
           aes(x = threshold,
               y = ndrop))+
    geom_line()+
    geom_point()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Document Similarity (Correlation)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Correlation Similarity Threshold",
        y = "Number of Documents Above Threshold"
    )+
    scale_x_continuous(breaks = seq(0.8, 1, 0.02))+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position="bottom",
        legend.direction = "vertical"
    )
)







#+
#'# Create CSV Files

#+
#'## Full Data Set

csvname.full.en <- paste(datashort,
                    version.dash,
                    "EN_CSV_TESSERACT_FULL.csv",
                    sep = "_")

csvname.full.fr <- paste(datashort,
                    version.dash,
                    "FR_CSV_TESSERACT_FULL.csv",
                    sep = "_")


fwrite(data.tesseract.en,
       csvname.full.en,
       na = "NA")

fwrite(data.tesseract.fr,
       csvname.full.fr,
       na = "NA")



#'## Metadata Only
#' These files are the same as the full data set, minus the "text" variable.

csvname.meta.en <- paste(datashort,
                    version.dash,
                    "EN_CSV_TESSERACT_META.csv",
                    sep = "_")

csvname.meta.fr <- paste(datashort,
                    version.dash,
                    "FR_CSV_TESSERACT_META.csv",
                    sep = "_")


fwrite(meta.tesseract.en,
       csvname.meta.en,
       na = "NA")

fwrite(meta.tesseract.fr,
       csvname.meta.fr,
       na = "NA")




#'# Final File Count per Folder
#' **Note:** Strictly speaking one of the German documents (the Danzig Courts file) is not a true original, as it was split from a bilingual file. However the quality of the document (scan and OCR) is original, so it is stored with the other originals to avoid creating another variant for a single document. This is the reason why the "MULT" variant contains 265 files instead of the maximum 264 that were downloaded from the ICJ website.


dir.table <- as.data.table(dirset)[, {
    filecount <- lapply(dirset,
                        function(x){length(list.files(x))})
    list(dirset, filecount)
}]


kable(dir.table,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      linesep = "",
      col.names = c("Directory",
                    "Filecount"))







#'# File Size Distribution

#'## English

#'### Corpus Object in RAM

print(object.size(corpus.en.b),
      humanReadable = TRUE,
      units = "MB")


#'### Create Data Table of Filenames

enhanced <- list.files("EN_PDF_ENHANCED_FULL",
                       full.names = TRUE)

original <- list.files("MULT_PDF_ORIGINAL_FULL",
                       full.names = TRUE)

MB <- file.size(enhanced) / 10^6

dt1 <- data.table(MB, rep("ENHANCED",
                          length(MB)))


MB <- file.size(original) / 10^6

dt2 <- data.table(MB, rep("ORIGINAL",
                          length(MB)))


dt <- rbind(dt1,
            dt2)
setnames(dt,
         "V2",
         "variant")


#'### Total Size Comparison

kable(dt[,
         .(MB_total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


#'### Analyze Files Larger than 10 MB

summary(dt[MB > 10]$MB)


#'\newpage
#'### Plot Density Distribution for Files 10MB or Less
dt.plot <- dt[MB <= 10]


#+ CD-PCIJ_EN_20_FileSizesDensity_Less10MB, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.plot,
           aes(x = MB,
               group = variant,
               fill = variant))+
    geom_density()+
    theme_bw()+
    facet_wrap(~variant,
               ncol = 2) +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      version,
                      "| Distribution of File Sizes up to 10 MB"),
        caption = paste("DOI:",
                        doi.version),
        x = "File Size in MB",
        y = "Density"
    )+
    scale_x_continuous(breaks = seq(0, 10, 2))+
    scale_fill_viridis(end = 0.35, discrete = TRUE) +
    scale_color_viridis(end = 0.35, discrete = TRUE) +
    theme(
        text = element_text(size=  14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        panel.spacing = unit(0.1,
                             "lines"),
        axis.ticks.x = element_blank()
    )
)

#'\newpage
#'## French

#'### Corpus Object in RAM

print(object.size(corpus.fr.b),
      humanReadable = TRUE,
      units = "MB")


#'### Create Data Table of filenames

enhanced <- list.files("FR_PDF_ENHANCED_FULL",
                       full.names = TRUE)

original <- list.files("MULT_PDF_ORIGINAL_FULL",
                       full.names = TRUE)


MB <- file.size(enhanced) / 10^6
dt1 <- data.table(MB,
                  rep("ENHANCED",
                      length(MB)))



MB <- file.size(original) / 10^6

dt2 <- data.table(MB,
                  rep("ORIGINAL",
                      length(MB)))


dt <- rbind(dt1,
            dt2)
setnames(dt,
         "V2",
         "variant")



#'### Total Size Comparison

kable(dt[,
         .(MB_total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


#'### Analyze Files Larger than 10 MB

summary(dt[MB > 10]$MB)



#'\newpage
#'### Plot Density Distribution for Files 10MB or Less

dt.plot <- dt[MB <= 10]

#+ CD-PCIJ_FR_20_FileSizesDensity_Less10MB, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.plot,
           aes(x = MB,
               group = variant,
               fill = variant)) +
    geom_density() +
    theme_bw() +
    facet_wrap(~variant,
               ncol = 2) +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      version,
                      "| Distribution of File Sizes up to 10 MB"),
        caption = paste("DOI:",
                        doi.version),
        x = "File Size in MB",
        y = "Density"
    )+
    scale_fill_viridis(end = 0.35, discrete = TRUE) +
    scale_color_viridis(end = 0.35, discrete = TRUE) +
    scale_x_continuous(breaks = seq(0, 10, 2))+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        panel.spacing = unit(0.1,
                             "lines"),
        axis.ticks.x = element_blank()
    )
)







#'# Create ZIP Archives

#+
#'## ZIP CSV Files

csv.zip.name.full.en <- gsub(".csv",
                             "",
                             csvname.full.en)

csv.zip.name.full.fr <- gsub(".csv",
                             "",
                             csvname.full.fr)

csv.zip.name.meta.en <- gsub(".csv",
                             "",
                             csvname.meta.en)

csv.zip.name.meta.fr <- gsub(".csv",
                             "",
                             csvname.meta.fr)

#+ results = 'hide'
zip(csv.zip.name.full.fr,
    csvname.full.fr)

zip(csv.zip.name.full.en,
    csvname.full.en)

zip(csv.zip.name.meta.fr,
    csvname.meta.fr)

zip(csv.zip.name.meta.en,
    csvname.meta.en)


#'## ZIP Data Directories

#' **Note:** Vector of Directories was created at the beginning of the script.

for (dir in dirset){
    zip(paste(datashort,
              version.dash,
              dir,
              sep = "_"),
        dir)
}


#'\newpage
#'## ZIP ANALYSIS Directory

zip(paste(datashort,
          version.dash,
          "EN-FR",
          basename(outputdir),
          sep = "_"),
    basename(outputdir))




#'## ZIP Source Files

files.source <-  c(list.files(pattern = "\\.R$|\\.toml$|\\.md$|\\.Rmd$"),
                   "data",
                   "functions",
                   "tex",
                   "buttons",
                   list.files(pattern = "renv\\.lock|\\.Rprofile",
                              all.files = TRUE),
                   list.files("renv",
                              pattern = "activate\\.R",
                              full.names = TRUE))




files.source <- grep("spin",
                     files.source,
                     value = TRUE,
                     ignore.case = TRUE,
                     invert = TRUE)

zip(paste(datashort,
          version.dash,
          "Source_Files.zip",
          sep = "_"),
    files.source)





#'# Delete CSV and Directories
#' The metadata CSV files are retained for Codebook generation.

#+
#'## Delete CSV Data Set
unlink(csvname.full.fr)
unlink(csvname.full.en)
unlink(csvname.meta.fr)
unlink(csvname.meta.en)


#'## Delete Data Directories
for (dir in dirset){
    unlink(dir,
           recursive = TRUE)
}






#'# Cryptography Module
#' This module computes two types of hashes for every ZIP archive: SHA2-256 and SHA3-512. These are proof of the authenticity and integrity of data and document that the files are the result of this source code. The SHA-2 and SHA-3 family of algorithms are highly resistant to collision and pre-imaging attacks in reasonable scenarios and can therefore be considered secure according to current public cryptographic research. SHA3 hashes with an output length of 512 bit may even provide sufficient security when attacked with quantum cryptanalysis based on Grover's algorithm.


#+
#'## Create Set of ZIP Archives
files.zip <- list.files(pattern= "\\.zip$",
                        ignore.case = TRUE)
                       


#'## Show Function: f.dopar.multihashes
#+ results = "asis"
print(f.dopar.multihashes)


#'## Compute Hashes
multihashes <- f.dopar.multihashes(files.zip)


#'## Convert to Data Table
setDT(multihashes)



#'## Add Index
multihashes$index <- seq_len(multihashes[,.N])

#'\newpage
#'## Save to Disk
fwrite(multihashes,
       paste(datashort,
             version.dash,
             "CryptographicHashes.csv",
             sep = "_"),
       na = "NA")


#'## Add Whitespace to Enable Automatic Linebreak
multihashes$sha3.512 <- paste(substr(multihashes$sha3.512, 1, 64),
                              substr(multihashes$sha3.512, 65, 128))


#'\newpage
#'## Print to Report

kable(multihashes[,.(index,filename)],
      format = "latex",
      align = c("p{1cm}",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE)


#'\newpage
kable(multihashes[,.(index,sha2.256)],
      format = "latex",
      align = c("c",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE) 


#'\newpage

kable(multihashes[,.(index,sha3.512)],
      format = "latex",
      align = c("c",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE)









#'# Finalize



#+
#'## Datestamp
print(datestamp)


#'## Date and Time (Begin)
print(begin.script)


#'## Date and Time (End)
end.script <- Sys.time()
print(end.script)


#'## Script Runtime
print(end.script - begin.script)


#'## Warnings
warnings()




#'# Strict Replication Parameters
sessionInfo()

system2("openssl",
        "version",
        stdout = TRUE)

system2("tesseract",
        "-v",
        stdout = TRUE)

system2("convert",
        "--version",
        stdout = TRUE)

print(quanteda_options())





#+
#'# References
