library(dplyr)

# Read the simulated data set from SAS.
simulated_full_data = haven::read_sas("Multiple Imputation/Simulated Data Set/simulated_full_data.sas7bdat")
simulated_full_data = simulated_full_data %>%
  arrange(id)
simulated_missing_data = simulated_full_data
# Read the original data containing missing values.
original_data = haven::read_sas("data preparation and exploration/final.sas7bdat")
original_data  = original_data %>%
  arrange(id)

# Loop over the columns of both data sets.
for (i in 1:ncol(simulated_full_data)) {
  # Both data sets are sorted by id. So if a value is missing in the original
  # data, we set the corresponding observation to missing in the simulated data.
  simulated_missing_data[is.na(original_data[, i]), i] = NA
}

# Save simulated data set, now with missing values, to disk.
haven::write_sav(simulated_missing_data, path = "Multiple Imputation/Simulated Data Set/simulated_missing_data.sav")
saveRDS(simulated_missing_data, file = "Multiple Imputation/Simulated Data Set/simulated_missing_data.rds")
write.csv(simulated_missing_data, file = "Multiple Imputation/Simulated Data Set/simulated_missing_data.csv")
# The simulated data set with no missing values is also saved to disk in various
# formats.
haven::write_sav(simulated_full_data, path = "Multiple Imputation/Simulated Data Set/simulated_full_data.sav")
saveRDS(simulated_full_data, file = "Multiple Imputation/Simulated Data Set/simulated_full_data.rds")
write.csv(simulated_full_data, file = "Multiple Imputation/Simulated Data Set/simulated_full_data.csv")
