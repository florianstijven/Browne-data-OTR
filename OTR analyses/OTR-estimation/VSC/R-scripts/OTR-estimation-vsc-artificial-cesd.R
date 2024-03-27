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
imputed_data_file_update1_per_arm = "/data/leuven/351/vsc35197/OTR/Browne/Multiple Imputation/Artificial Data for Illustrations/final_mi_updated1_per_arm.sas7bdat"
imputed_data_file_update1_global = "/data/leuven/351/vsc35197/OTR/Browne/Multiple Imputation/Artificial Data for Illustrations/final_mi_updated1_global.sas7bdat"
saveto = "/data/leuven/351/vsc35197/OTR/Browne/"
# Specify options for parallel computations.
ncores = 36

# Source file that contains the function to estimate the treatment regime given
# a selection of options.
source(file = "/data/leuven/351/vsc35197/OTR/Browne/OTR_estimator.R")

imputed_data_update1_per_arm = read.sas7bdat(imputed_data_file_update1_per_arm)
imputed_data_update1_global = read.sas7bdat(imputed_data_file_update1_global)

# Join the sets of imputed data sets while adding a variable that indicates the
# type of imputation.
imputed_data = bind_rows(
  imputed_data_update1_per_arm %>%
    mutate(imputation = "Per Arm",
           update = 1L),
  imputed_data_update1_global %>%
    mutate(imputation = "Global",
           update = 1L)
)

# Drop third treatment arm.
imputed_data = imputed_data %>%
  dplyr::filter(group != 3)
# Recode the group, sex, and disorder variables into a factor variables.
imputed_data = imputed_data %>%
  mutate(group = factor(
    group,
    labels = c("Sertraline alone", "Sertraline and IPT"),
    levels = 1:2
  ),
  sex = factor(
    sex,
    labels = c("Male", "Female"),
    levels = 1:2
  ),
  disorder = factor(
    disorder,
    labels = c("Never", "Past", "Current", "Current and Past"),
    levels = 1:4
  ))
# Recode disorder variable into two binary variables.
imputed_data = imputed_data %>%
  mutate(
    past_MDD = fct_collapse(
      .f = disorder,
      "No" = c("Never", "Current"),
      "Yes" = c("Past", "Current and Past")
    ),
    current_MDD = fct_collapse(
      .f = disorder,
      "No" = c("Never", "Past"),
      "Yes" = c("Current", "Current and Past")
    )
  )
imputed_data %>% head()
# Data are transformed from wide to long format. In the long data set, there is
# one row for each post-randomization outcome.
imputed_data_long = imputed_data %>%
  pivot_longer(
    cols = 14:28,
    names_to = c("outcome", "time"),
    values_to = "value",
    names_sep = -1
  ) %>%
  mutate(time = fct_recode(
    .f = time,
    "6 months" = "2",
    "1 year" = "3",
    "2 years" = "4"
  ))
# Change variable names to improve consistency.
imputed_data_long = imputed_data_long %>%
  dplyr::rename(madrs = madrsv1, sas = sasb) %>%
  mutate(outcome = ifelse(outcome == "madrst", "madrs", outcome),
         outcome = ifelse(outcome == "sasb", "sas", outcome))
# In addition to the observed scale at each time point, we add the change from 
# baseline as an additional outcome. 
imputed_data_long = imputed_data_long %>%
  mutate(change_score = 
           ifelse(outcome == "madrs", madrs - value, 0) +
           ifelse(outcome == "sas", sas - value, 0) +
           ifelse(outcome == "famfun", famfun - value, 0) +
           ifelse(outcome == "cesd", cesd - value, 0) +
           ifelse(outcome == "vas", value - vas, 0),
         # We also add a numeric variable for the treatment.
         group_int = as.integer(group) - 1)

# Print group means across imputed data sets as a check to the processed data
# integrity.
imputed_data_long %>%
  group_by(outcome, time, group, group_int) %>%
  summarise(mean_score = mean(change_score))

# Only select observations at 6 months.
imputed_data_long_6months = imputed_data_long %>%
  dplyr::filter(time == "6 months")

# Split data set according to outcome variable, imputation number, imputation
# method, and update version. The first four columns of the new tibble contain,
# respectively, the imputation number, outcome variable, imputation method, and
# update version.
imputed_data_reformatted = imputed_data_long_6months %>%
  group_by(X_Imputation_, outcome, imputation, update) %>%
  dplyr::summarise(data_set = list(pick(everything())))

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
        file = paste0(saveto, "OTR_artificial_results_", outcome_name, ".rds"))

