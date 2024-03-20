# Load required packages.
library(DynTxRegime)
library(sas7bdat)
library(dplyr)
library(tidyr)
library(forcats)


# Specify location of data files needed further on.
imputed_data_file_update1_per_arm = "Multiple Imputation/Artificial Data for Illustrations/final_mi_updated1_per_arm.sas7bdat"
imputed_data_file_update1_global = "Multiple Imputation/Artificial Data for Illustrations/final_mi_updated1_global.sas7bdat"

saveto = "OTR analyses/OTR-estimation/"

imputed_data_update1_per_arm = read.sas7bdat(imputed_data_file_update1_per_arm)
imputed_data_update1_global = read.sas7bdat(imputed_data_file_update1_global)

# Join the sets of imputed data sets while adding a variable that indicates the
# type of imputation.
imputed_data = bind_rows(
  imputed_data_update1_per_arm %>%
    mutate(imputation = "Per Arm",
           outcome_model = "Correct",
           update = 1L),
  imputed_data_update1_global %>%
    mutate(imputation = "Global",
           outcome_model = "Correct",
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

# Only select observations at 6 months for cesd.
imputed_data_long_6months = imputed_data_long %>%
  dplyr::filter(time == "6 months", outcome == "cesd") %>%
  mutate(age_sq = age**2, cesd_sq = cesd**2)

# Split data set according to outcome variable, imputation number, imputation
# method, and update version. The first four columns of the new tibble contain,
# respectively, the imputation number, outcome variable, imputation method,
# outcome model, size of quadratic effect, and update version.
imputed_data_reformatted = imputed_data_long_6months %>%
  group_by(X_Imputation_, outcome, imputation, update, outcome_model) %>%
  dplyr::summarise(data_set = list(pick(everything())))

# The optimal treatment regime with q-learning is estimated. We start by
# defining a function that performs the OTR estimation for a single imputed data
# set and outcome.
OTR_estimator = function(outcome,
                         main_covariates,
                         cont_covariates,
                         treatment,
                         data) {
  # Formula for the v- and c-functions are constructed from the character
  # vectors in main_covariates and cont_covariates.
  main_formula = as.formula(paste("~", paste(main_covariates, collapse = " + ")))
  cont_formula = as.formula(paste("~", paste(cont_covariates, collapse = " + ")))
  
  # The outcome regression part of the AIPW estimator is specified in two parts.
  # First, the v function contains the main effects. Second, the c function
  # contains interaction effects.
  
  # Build the v-function.
  q1d_Main <- modelObj::buildModelObj(
    model = main_formula,
    solver.method = 'lm',
    predict.method = 'predict.lm'
  )
  # Build the c-function. In contrast to the value search estimator, the form of
  # the optimal regime is determined by this c-function. So, we only use the
  # interaction terms that were selected by the lasso for this c-function.
  q1d_Cont <- modelObj::buildModelObj(
    model = cont_formula,
    solver.method = 'lm',
    predict.method = 'predict.lm'
  )
  # Estimate optimal treatment regime through q-learning.
  AIPW1d <- DynTxRegime::qLearn(
    moMain = q1d_Main,
    moCont = q1d_Cont,
    data = as.data.frame(data),
    response = data$change_score,
    txName = "group_int",
    verbose = TRUE
  )
  return(AIPW1d)
}


# Apply q-learning to each individual data set.
results_tbl = imputed_data_reformatted %>%
  mutate(regime = purrr::map(
    .x = data_set,
    .f = function(data,
                  main_covariates,
                  cont_covariates,
                  treatment) {
      main_covariates = c(
        "sex",
        "past_MDD",
        "current_MDD",
        "phealth",
        "age",
        "madrs",
        "sas",
        "famfun",
        "cesd",
        "vas"
      )
      cont_covariates = c("sex", "age", "famfun", "cesd", "past_MDD")
      treatment = "group_int"
      OTR_estimator(data$change_score,
                    main_covariates,
                    cont_covariates,
                    treatment,
                    data)
    }
  )) %>%
  select(-data_set)
  

saveRDS(object = results_tbl, file = paste0(saveto, "OTR_q_results_update.rds"))
