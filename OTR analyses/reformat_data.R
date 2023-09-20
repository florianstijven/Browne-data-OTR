reformat_data = function(imputed_data_compatible, imputed_data_incompatible) {
  # Data
  # Load sas data sets into R. 
  imputed_data_compatible = read.sas7bdat(imputed_data_file_compatible)
  imputed_data_incompatible = read.sas7bdat(imputed_data_file_incompatible)
  
  # Join the sets of imputed data sets while adding a variable that indicates the
  # type of imputation.
  imputed_data = bind_rows(
    imputed_data_compatible %>%
      mutate(imputation = "compatible"),
    imputed_data_incompatible %>%
      mutate(imputation = "incompatible")
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
  
  # Split data set according to outcome variable, imputation number and imputation
  # method. The first three columns of the new tibble contain, respectively, the
  # imputation number, outcome variable, and imputation method.
  imputed_data_reformatted = imputed_data_long_6months %>%
    group_by(X_Imputation_, outcome, imputation) %>%
    dplyr::summarise(data_set = list(pick(everything())))
  
  return(imputed_data_reformatted)
}