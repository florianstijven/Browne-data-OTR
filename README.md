# Introduction

This repository contains all code that were used in the analysis of the Browne
data, and of which the results are presented in Stijven et al. (2023). The code 
is organized in four parts:

1. Code used for data preparation, SAS 9.4 was used here. 
2. Code used for exploring missing data and performing multiple imputation. SAS 
9.4 and R have been used here.
3. Code used for estimation of optimal treatment regimes. This code is organized
in R-scripts, and has been run on high-performance computing (HPC) infrastructure
(Vlaams Supercomputer Centrum, VSC).
4. Code used for processing, analyzing, and summarizing the estimated optimal
treatment regimes. This code is organized in Rmarkdown files. The reports output
by these Rmarkdown files are included in this repository, both in html and word
format.

In the following sections, we describe the files present in this repository in
more details. The code itself has also been thoroughly documented to
improve readability.

# Data Preperation

All code for preparing the data is included in `data preparation and
exploration/Data reading and preparation.sas`. Note that both the original data
files, as well as the processed data files, are not included in this repository.
These data are owned by a third party and can therefore not be shared.

The `formats.sas7bcat` file contains formatting information for the sas data 
files. 

# Missing Data and Multiple Imputation

All code related to exploring missing data and performing multiple imputation resides
in the `Mutliple Imputation/` directory. 

The `Multiple Imputation/exploration_of_missingness.Rmd` file contains code (and
prose) for exploring the missingness. The html and word documents output by this
Rmarkdown file are also included under the same name.

The `Multiple Imputation/Compatible MI/MI.sas` and `Mutliple
Imputation/Incompatible MI/MI.sas` files contain the code for performing
imputation per arm and global impution, respectively. For the same reasons as before,
the imputed data sets are not included in this repository.

The `Multiple Imputation/Artificial Data for Illustrations/` directory contains 
all code related to the artificial Browne data. These are the Browne data where
we artificially induced stronger treatment effect heterogeneity:

* `construction_of_artificial_data.sas`: sas code for "updating" the Browne data,
that is, for adding artificial treatment effect heterogeneity.
* `MI_per_arm_update_1.sas`: sas code for performing imputation per arm on the artificial
Browne data.
* `MI_global.sas`: sas code for performing global imputation on the artificial 
Browne data.
* `artificial_data_motivation_for_offsets.Rmd`: Rmarkdown file where the original
Browne data and artificial Browne data are being compared. The html and word documents
output by this Rmarkdown file are also included under the same name.

# Estimation of Optimal Treatment Regimes

There are multiple locations with code for estimating optimal treatment regimes. 

1. `OTR analyses/OTR-estimation`: This folder contains the code for Q-learning 
and value search estimation in the original Browne data and the artificial Browne 
data. 
    - `./q-learning.R` `./q-learning-artificial-data.R` contain the code for 
    performing Q-learning in the original Browne data and artificial Browne data,
    respectively.
    - `./VSC` contains code that was run on HPC infrastructure. This code was used 
    for value search estimation. This code are
    organized in three sub directories:
        1. `./VSC/R-scripts`: This directory contains the R-scripts that were 
        run on the HPC infrastructure.
        2. `./VSC/job-files`: This directory contains the slurm files that were used
        to submit jobs to the HPC infrastructure. 
        3. `./VSC/results`: This directory contains the output from running the 
        R-scripts.
        Note that only output to the console is included in this directory. The 
        objects containing the estimated optimal regimes cannot be included in
        this repository because they contain the original data.
2. `OTR analyses/tuning-parameters`: This folder contains the code implementing 
the value search estimator that was used for exploring the performance of various
tuning parameters. The `./VSC` folder is organized in the same manner as 
explained before.
The `./tuning-parameters-results.Rmd` file is where the estimated regimes under
various tuning parameters are summarized and compared. The associated html and word
documents have also been included under the same name.

The `OTR analyses/` directory also contains the following helper files:
`OTR_estimator.R`, `reformat_data.R`, `swv_ML.R`, `swv_OLS.R`, `value_AIPW.R`,
`value_AIPW_se.R`, `value_AIPW_swv.R`. These files are sourced in other R-scripts
and Rmarkdown files. We wrote the former two files to remove redundancies in our code.
The other helper files were downloaded from the [website](https://laber-labs.com/dtr-book/booktoc.html) accompanying the book
*Dynamic Treatment Regimes: Statistical Methods for Precision Medicine*.
  
  
# Processing of Results

The `OTR estimation/final-summary.Rmd` file contains the main code that is used
for processing the estimated optimal treatment regimes. This file contains a
very comprehensive analysis of the estimated treatment regimes in the original
Browne data. The html and word documents output by this Rmarkdown file are also
included under the same name.

While the Rmarkdown files generate independent reports, they also contain code
that saves the figures presented in the paper into the `figures-manuscript/`
folder.

