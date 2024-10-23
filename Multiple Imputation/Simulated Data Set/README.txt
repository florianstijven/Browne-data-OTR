The simulated data set is structured like the original data. These data were simulated by first making a new data set
containing only the id, group (i.e., treatment), and sex variables from the original data (keeping all rows from the original 
data). The orignal and new data set were then concatenated and compatible imputation (described elsewhere)
was performed once on the "combined" data set. Next, the rows in the singly imputed data set that correspond to the original data
were deleted. This leaves us with a data set where all variables were imputed except id, group, and sex. The thus generated
data set corresponds to simulated_full_data.csv (and identically named files with different file extensions). Next, for each 
row in simulated_full_data.csv, we made all observations missing that were missing in the correponding row (matched on id) 
in the original data. The thus generated data set corresponds to simulated_missing_data.csv (and identically named files 
with different file extensions). 

The simulated data sets are available in .csv, .sav, and .rds format. The continuous variables are 
described below:

* id: patient id
* age: age at baseline
* numchild: number of children at baseline
* phealth: perceived health at baseline, integer scale from 1 to 5
* madrsv1: Montgomery Asberg Depression Rating Scale (MADRS) at baseline
* sasb: Social Adjustment Scale (SAS) at baseline
* famfun: McMaster Family Assessment Device (FAMFUN) at baseline
* cesd: Center for Epidemiologic Studies Depression Scale (CESD) at baseline
* vas: Visual Analogue Scale (VAS) at baseline, integer scale from 1 to 100
* madrst2-4: MADRS at i'th postrandomization visit (6 months, 1 year, 2 years)
* sasb2-4: SAS at i'th postrandomization visit (6 months, 1 year, 2 years)
* famfun2-4: FAMFUN at i'th postrandomization visit (6 months, 1 year, 2 years)
* cesd2-4: CESD at i'th postrandomization visit (6 months, 1 year, 2 years)
* vas2-4: VAS at i'th postrandomization visit (6 months, 1 year, 2 years)

The coding of the categorical variables is described below:

* group (randomized treatment):
	-1: Sertraline alone
	-2: Sertraline and interpersonal psychotherapy
	-3: Interpersonal psychotherapy alone
* sex:
	-1: Male
	-2: Female
* disorder (past and/or current majord depressive disorder):
	-1: Never
	-2: Past
	-3: Current
	-4: Current and past