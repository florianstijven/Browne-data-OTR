#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
# First argument is the name of the outcome variable
outcome_name = args[1]
print(outcome_name)
# Load required packages.
.libPaths("/data/leuven/351/vsc35197/R/")
# library(plyr)
library(doParallel)
library(sas7bdat)
library(dplyr)
library(tidyr)
library(forcats)
library(DynTxRegime)
library(rgenoud)

# Specify location of data files needed further on.
imputed_data_file_compatible = "/data/leuven/351/vsc35197/OTR/Browne/Multiple Imputation/Compatible MI/final_mi.sas7bdat"
imputed_data_file_incompatible = "/data/leuven/351/vsc35197/OTR/Browne/Multiple Imputation/Incompatible MI/final_mi_incompatible.sas7bdat"
saveto = "/data/leuven/351/vsc35197/OTR/Browne/"
# Specify options for parallel computations.
ncores = 36

# Source file that contains the function to reformat the sas data files into an
# appropriate format that simplifies further processing.
source(file = "/data/leuven/351/vsc35197/OTR/Browne/reformat_data.R")
# Source file that contains the function to estimate the treatment regime given
# a selection of options.
source(file = "/data/leuven/351/vsc35197/OTR/Browne/OTR_estimator.R")

imputed_data_reformatted = reformat_data(imputed_data_file_compatible,
                                         imputed_data_file_incompatible)

# For each outcome, we only use a combination of the "optimal" tuning parameters
# that were found previously. This is a population size of 500 with 20
# independent runs and a population size of 3000 with 5 independent runs.
imputed_data_reformatted =
  bind_rows(
    imputed_data_reformatted %>%
      # 20 Independent runs with a population size of 500.
      cross_join(y = tibble(seed = c(101:120))) %>%
      mutate(population_size = 500),
    imputed_data_reformatted %>%
      # 5 Independent runs with a population size of 3000.
      cross_join(y = tibble(seed = c(11:15))) %>%
      mutate(population_size = 3000)
  ) %>%
  filter(outcome == outcome_name)

# Add a column with the type of starting values as variable. The starting values
# provided by Q-learning were found to perform best and are therefore used here.
imputed_data_reformatted = imputed_data_reformatted %>%
  mutate(starting_value = "Q")


imputed_data_reformatted_list = split(imputed_data_reformatted, seq(nrow(imputed_data_reformatted)))

# Apply the value search estimator to each individual data set.
a = Sys.time()
print(detectCores())

registerDoParallel(cores=ncores)

OTR_estimated_list = plyr::llply(
  .data = imputed_data_reformatted_list,
  .fun = function(x, wait_generations) {
    data = x$data_set[[1]]
    seed = x$seed[1]
    pop_size = x$population_size[1]
    starting_values = x$starting_value[1]
    # Covariates used as main effects in the outcome regression in the AIPW
    # estimator. These are all available baseline covariates.
    main_covariates = c("sex",
                        "past_MDD",
                        "current_MDD",
                        "phealth",
                        "age",
                        "madrs",
                        "sas",
                        "famfun",
                        "cesd",
                        "vas")
    # Covariates to be used as interaction terms in the outcome regression in
    # the AIPWE and as covariates in the treatment regime. These covariates have
    # been selected on substantive grounds.
    cont_covariates = c("sex", "age", "famfun", "cesd", "past_MDD")
    regime = OTR_estimator(outcome = data$change_score,
                           main_covariates = main_covariates,
                           cont_covariates = cont_covariates,
                           treatment =  "group_int",
                           data = data,
                           seed = seed, 
                           pop_size = pop_size,
                           wait_generations = wait_generations,
                           starting_values = starting_values)
    return(regime)
  },
  wait_generations = 10L,
  .parallel = TRUE, 
  .progress = "text"
)

print(Sys.time() - a)

# Drop column that contains the data sets and add new column containing the
# results of variable selection.
results_tbl = imputed_data_reformatted %>%
  select(-data_set)
results_tbl$OTR_estimated = OTR_estimated_list

saveRDS(object = results_tbl,
        file = paste0(saveto, "OTR_results_", outcome_name, ".rds"))


