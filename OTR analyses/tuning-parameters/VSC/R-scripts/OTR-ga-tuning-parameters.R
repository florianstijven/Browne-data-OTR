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
saveto = "/data/leuven/351/vsc35197/OTR/Browne/tuning-parameters/"
# Specify options for parallel computations.
ncores = 36


# Source file that contains the function to reformat the sas data files into an
# appropriate format that simplifies further processing.
source(file = "/data/leuven/351/vsc35197/OTR/Browne/reformat_data.R")
# Source file that contains the function to estiamte the treatment regime given
# a selection of options.
source(file = "/data/leuven/351/vsc35197/OTR/Browne/OTR_estimator.R")

imputed_data_reformatted = reformat_data(imputed_data_file_compatible,
                                         imputed_data_file_incompatible)

# Drop rows with incompatible imputation. Since we're only looking at the
# performance of the optimization algorithm, we don't need to look at
# incompatible imputation also.

# Only use the first 20 imputed data sets. We do not use all imputed data sets
# because of the computation burden.
imputed_data_reformatted = imputed_data_reformatted %>%
  filter(imputation == "compatible", X_Imputation_ <= 20)

# Add a column with seed number as variable. For the purposed of our exploration
# of the effect of different tuning parameter settings, we need to run each
# genetic algorithm 6 times with a different seed. To distinguish clearly
# between settings, we use non-consecutive seeds.
imputed_data_reformatted = imputed_data_reformatted %>%
  cross_join(y = tibble(seed = c(1, 11:15, 101:120)))
  
# Add a column with the population size as variable. 
imputed_data_reformatted = imputed_data_reformatted %>%
  cross_join(y = tibble(population_size = c(500, 1000, 3000)))

# Only for a small population size of 500, the multi-run setting with 20 runs
# will be considered. 
imputed_data_reformatted = imputed_data_reformatted %>%
  filter(!((seed > 100) & (population_size > 500)))

  
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
                           wait_generations = wait_generations)
    return(regime)
  },
  wait_generations = 10L,
  .parallel = TRUE, 
  .progress = "text"
)

print(Sys.time() - a)

# Drop column that contains the data sets.
results_tbl = imputed_data_reformatted %>%
  select(-data_set)
results_tbl$OTR_estimated = OTR_estimated_list

saveRDS(object = results_tbl, file = paste0(saveto, "OTR_results-tuning-parameters.rds"))
