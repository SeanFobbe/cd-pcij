# Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ)

## Overview

This R script downloads and processes the full set of decisions and appended opinions rendered by the Permanent Court of International Justice (PCIJ) --- as published in Series A, B and AB on <https://www.icj-cij.org> --- into a rich and structured human- and machine-readable data set. It is the basis of the **Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ)**.

All data sets created with this script will always be hosted permanently open access and freely available at Zenodo, the scientific repository of CERN. Each version is uniquely identified with a persistent Digitial Object Identifier (DOI), the *Version DOI*. The newest version of the data set will always available via the link of the *Concept DOI*: <https://doi.org/10.5281/zenodo.3840479>


## Functionality
 
 This script will produce 17 ZIP archives:
 
- 2 archives of CSV files containing the full machine-readable data set (English/French)
- 2 archives of CSV files containing the full machine-readable metadata (English/French)
- 2 archives of TXT files containing all machine-readable texts with a reduced set of metadata encoded in the filenames (English/French)
- 2 archives of PDF files containing all human-readable texts with enhanced OCR (English/French)
- 2 archives of PDF files containing all human-readable majority opinions with enhanced OCR (English/French)
- 2 archives of PDF files containing original documents split into monolingual documents (English/French)
- 2 archives of TXT files containing extracted text from the original documents (English/French)
- 1 archive of PDF files as originally published by the PCIJ/ICJ (multilingual)
- 1 archive of analysis data and diagrams
- 1 archive containing all source files
 
 The integrity and veracity of each ZIP archive is documented with cryptographically secure hash signatures (SHA2-256 and SHA3-512). Hashes are stored in a separate CSV file created during the data set compilation process.
 
 Please refer to the Codebook regarding the relative merits of each variant. Unless you have very specific needs you should only use the variants denoted 'TESSERACT' or 'ENHANCED' for serious work.
 



## System Requirements

- You must have the [R Programming Language](https://www.r-project.org/) and all **R packages** listed under the heading 'Load Packages' installed.
- You must have the system dependencies **tesseract** and **imagemagick** (on Fedora Linux, names may differ with other Linux distibutions) installed for the OCR pipeline to work.
 - Due to the use of Fork Clusters and system commands the script as published will (probably) only run on Fedora Linux. The specific version of Fedora used is documented as part of the session information at the end of this script. With adjustments it may also work on other distributions. 
- Parallelization will automatically be customized to your machine by detecting the maximum number of cores. A full run of this script takes approximately 90 minutes on a machine with a Ryzen 3700X CPU using 16 threads, 64 GB DDR4 RAM and a fast SSD.
- You must have the **openssl** system library installed for signature generation. If you prefer not to generate signatures this part of the script can be removed without affecting other parts, but a missing signature CSV file will result in non-fatal errors during Codebook compilation.
- Optional code to compile a high-quality PDF report adhering to standards of strict reproducibility is included. This requires the R packages **rmarkdown**, **magick**, an installation of **LaTeX** and all the packages specified in the TEX Preamble file.





## Compilation

All comments are in **roxygen2-style** markup for use with *spin()* or *render()* from the **rmarkdown** package. Compiling the scripts will produce the full data set, high-quality PDF reports and save all diagrams to disk. 

Both scripts can be executed as ordinary R scripts without any of the markdown and report generation elements. The Corpus creation script will also produce the full data set. No diagrams or reports will be saved to disk in this scenario.

To compile the full data set, a Compilation Report and the Codebook, copy all files provided in the Source ZIP Archive into an empty (!) folder and run the following command in an R session:


```
source("run_project.R")
```



## Open Access Publications (Fobbe)

Website --- https://www.seanfobbe.com

Open Data --- https://zenodo.org/communities/sean-fobbe-data

Code Repository --- https://zenodo.org/communities/sean-fobbe-code

Regular Publications --- https://zenodo.org/communities/sean-fobbe-publications

 

## Contact

Did you discover any errors? Do you have suggestions on how to improve the data set? You can either post these to the Issue Tracker on GitHub or write me an e-mail at [fobbe-data@posteo.de](mailto:fobbe-data@posteo.de)

