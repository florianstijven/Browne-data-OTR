library(tidyverse)
library(gtsummary)
library(sas7bdat)

# Load the original data.
original_data = read.sas7bdat(file = "data preparation and exploration/final.sas7bdat")
# Recode categorical variables with informative labels.
original_data = original_data %>%
  filter(group != 3) %>%
  mutate(Treatment = factor(
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
original_data = original_data %>%
  mutate(
    "Past MDD" = fct_collapse(
      .f = disorder,
      "No" = c("Never", "Current"),
      "Yes" = c("Past", "Current and Past")
    ),
    "Present MDD" = fct_collapse(
      .f = disorder,
      "No" = c("Never", "Past"),
      "Yes" = c("Current", "Current and Past")
    ),
    sex_female = sex == "Female"
  )

# Produce Table 1 and save to a .txt file.
latex_table = original_data %>%
  tbl_summary(
    by = Treatment,
    include = c(
      sex_female,
      age,
      `Present MDD`,
      `Past MDD`,
      phealth,
      cesd,
      madrsv1,
      vas,
      sasb,
      famfun
    ) 
  ) %>% as_gt() %>%
  gt::as_latex()

mclm::write_txt(
  latex_table[1],
  file = "data preparation and exploration/table1.txt"
)
