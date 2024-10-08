/* Specify which directory contains the (processed) input data set. */
%let input_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/data preparation and exploration;
/* Specify which directory is to be used for output, i.e., to save the imputed data sets in. */
%let output_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/Multiple Imputation/Simulated Data Set;
/* Specify the number of imputations. We just need 1 imputation to simulate a new data set. */
%let n_imputations = 1;
/* Specify the number of burn-in iterations. 
The default is 25, but it's better to err on the side of caution. So, a value larger than 25 is preferred. */
%let n_burnin = 100;

/* Set libref to the directory that contains the processed data set with missing values.*/
libname indata "&input_directory";

/* Specify file with formatting options. Without this file, the data set cannot be properly read and SAS will give errors. */
OPTIONS FMTSEARCH = (indata.formats);

/* Load data set into the work library. */
data final;
set indata.final;
run;

/* Check whether the number of observations in each treatment group is correct. There should be a total of 707 - 44 patients randomized to one of the 3 
treatment groups: 215 to group 1 (Sertraline only), 238 to group 2 (Sertraline + IPT), and 210 to group 3 (IPT only). The 44 patients that did not start treatment 
have thus already been excluded. */
proc freq data=final;
	table group;
run;

/* Display the number of missing values for each variable. There are no missing values for id, group, sex, age, disorder, phealth, madrsv1, and cesd. */
proc means data=final nmiss min max;
run;

/* Create new rows in the data set with only missing values, except for treatment allocation. The number of rows for each group corresponds to the 
number of patients in each group in the original data. We also add a new variable to indicate which rows were added. */
data final;
	set final;
	original = 1;
run;

data final_removed;
	set final;
	original = 0;
	keep id group original sex;
run;


data joined;
	set final final_removed;
run;


/* We follow the same approach as "compatible imputation" described elsewhere in this data analysis project. */

/* We start by transforming the scales to the [1, 101] interval.
This ensures that the following logistic transformation does not lead to infinite values. */
data joined_transformed;
set joined;
madrsv1 = madrsv1*100/60 + 1; madrst2 = madrst2*100/60 + 1; madrst3 = madrst3*100/60 + 1; madrst4 = madrst4*100/60 + 1;
cesd = cesd*100/60 + 1; cesd2 = cesd2*100/60 + 1; cesd3 = cesd3*100/60 + 1; cesd4 = cesd4*100/60 + 1;
vas = vas + 1; vas2 = vas2 + 1; vas3 = vas3 + 1; vas4 = vas4 + 1;
sasb = (sasb - 1)*100/4 + 1; sasb2 = (sasb2 - 1)*100/4 + 1; sasb3 = (sasb3 - 1)*100/4 + 1; sasb4 = (sasb4 - 1)*100/4 + 1; 
famfun = (famfun - 1)*100/3 + 1;  famfun2 = (famfun2 - 1)*100/3 + 1; famfun3 = (famfun3 - 1)*100/3 + 1; famfun4 = (famfun4 - 1)*100/3 + 1;
run;

/* Check that all scales are in the [1, 101] interval */
proc means data=joined_transformed nmiss min max mean;
	var _all_;
run;

/* Proc MI: For group = 1 */
ods graphics on;
proc mi data=joined_transformed out=joined_MI_1 nimpute=&n_imputations seed=1;		
	where group = 1;
	class sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var sex disorder numchild phealth age
		madrsv1 madrst2 madrst3 madrst4
		cesd cesd2 cesd3 cesd4
		vas vas2 vas3 vas4
		sasb sasb2 sasb3 sasb4
		famfun famfun2 famfun3 famfun4;

transform 
logit(madrsv1 madrst2 madrst3 madrst4
	  cesd cesd2 cesd3 cesd4
	  vas vas2 vas3 vas4
	  sasb sasb2 sasb3 sasb4
	  famfun famfun2 famfun3 famfun4 / c = 102);
run;
ods graphics off;

/* Proc MI: For group = 2 */
ods graphics on;
proc mi data=joined_transformed out=joined_MI_2 nimpute=&n_imputations seed=2;		
	where group = 2;
	class sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var sex disorder numchild phealth age
		madrsv1 madrst2 madrst3 madrst4
		cesd cesd2 cesd3 cesd4
		vas vas2 vas3 vas4
		sasb sasb2 sasb3 sasb4
		famfun famfun2 famfun3 famfun4;

transform 
logit(madrsv1 madrst2 madrst3 madrst4
	  cesd cesd2 cesd3 cesd4
	  vas vas2 vas3 vas4
	  sasb sasb2 sasb3 sasb4
	  famfun famfun2 famfun3 famfun4 / c = 102);
run;
ods graphics off;

/* Proc MI: For group = 3 */
ods graphics on;
proc mi data=joined_transformed out=joined_MI_3 nimpute=&n_imputations seed=3;		
	where group = 3;
	class sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var sex disorder numchild phealth age
		madrsv1 madrst2 madrst3 madrst4
		cesd cesd2 cesd3 cesd4
		vas vas2 vas3 vas4
		sasb sasb2 sasb3 sasb4
		famfun famfun2 famfun3 famfun4;

transform 
logit(madrsv1 madrst2 madrst3 madrst4
	  cesd cesd2 cesd3 cesd4
	  vas vas2 vas3 vas4
	  sasb sasb2 sasb3 sasb4
	  famfun famfun2 famfun3 famfun4 / c = 102);
run;
ods graphics off;


/* The imputed data sets are joined into a single data set. */

data joined_MI;
	set joined_MI_1 joined_MI_2 joined_MI_3;
run;

/* We transform the variables in the full imputed data set back to the original scale. */
data joined_MI;
set joined_MI;
madrsv1 = (madrsv1 - 1)*60/100; madrst2 = (madrst2 - 1)*60/100; madrst3 = (madrst3 - 1)*60/100; madrst4 = (madrst4 - 1)*60/100;
cesd = (cesd - 1)*60/100; cesd2 = (cesd2 - 1)*60/100; cesd3 = (cesd3 - 1)*60/100; cesd4 = (cesd4 - 1)*60/100;
vas = vas - 1; vas2 = vas2 - 1; vas3 = vas3 - 1; vas4 = vas4 - 1;
sasb = (sasb - 1)*4/100 + 1; sasb2 = (sasb2 - 1)*4/100 + 1; sasb3 = (sasb3 - 1)*4/100 + 1; sasb4 = (sasb4 - 1)*4/100 + 1; 
famfun = (famfun - 1)*3/100 + 1;  famfun2 = (famfun2 - 1)*3/100 + 1; famfun3 = (famfun3 - 1)*3/100 + 1; famfun4 = (famfun4 - 1)*3/100 + 1;
run;

/* Further post-processing to ensure that the scale restrictions are satisfied for all imputed values. */
data joined_MI;
set joined_MI;

numchild = round(numchild, 1);
if numchild < 0 then numchild = 0;

madrsv1 = round(madrsv1, 1); madrst2 = round(madrst2, 1); madrst3 = round(madrst3, 1); madrst4 = round(madrst4, 1);
if madrsv1 < 0 then madrsv1 = 0; if madrst2 < 0 then madrst2 = 0; if madrst3 < 0 then madrst3 = 0; if madrst4 < 0 then madrst4 = 0;
if madrsv1 > 60 then madrsv1 = 60; if madrst2 > 60 then madrst2 = 60; if madrst3 > 60 then madrst3 = 60; if madrst4 > 60 then madrst4 = 60;

cesd = round(cesd, 1); cesd2 = round(cesd2, 1); cesd3 = round(cesd3, 1); cesd4 = round(cesd4, 1);
if cesd < 0 then cesd = 0; if cesd2 < 0 then cesd2 = 0; if cesd3 < 0 then cesd3 = 0; if cesd4 < 0 then cesd4 = 0;
if cesd > 60 then cesd = 60; if cesd2 > 60 then cesd2 = 60; if cesd3 > 60 then cesd3 = 60; if cesd4 > 60 then cesd4 = 60;

vas = round(vas, 1); vas2 = round(vas2, 1); vas3 = round(vas3, 1); vas4 = round(vas4, 1);
if vas < 0 then vas = 0; if vas2 < 0 then vas2 = 0; if vas3 < 0 then vas3 = 0; if vas4 < 0 then vas4 = 0;
if vas > 100 then vas = 100; if vas2 > 100 then vas2 = 100; if vas3 > 100 then vas3 = 100; if vas4 > 100 then vas4 = 100;

if sasb < 1 then sasb = 1; if sasb2 < 1 then sasb2 = 1; if sasb3 < 1 then sasb3 = 1; if sasb4 < 1 then sasb4 = 1;
if sasb > 5 then sasb = 5; if sasb2 > 5 then sasb2 = 5; if sasb3 > 5 then sasb3 = 5; if sasb4 > 5 then sasb4 = 5;

if famfun < 1 then famfun = 1; if famfun2 < 1 then famfun2 = 1; if famfun3 < 1 then famfun3 = 1; if famfun4 < 1 then famfun4 = 1;
if famfun > 4 then famfun = 4; if famfun2 > 4 then famfun2 = 4; if famfun3 > 4 then famfun3 = 4; if famfun4 > 4 then famfun4 = 4;

run;

/* Drop the original observations and the original column. */
data joined_mi;
	set joined_mi;
	if original = 1 then delete;
	drop original;
run;


/* Set libref to directory in which to save the imputed data sets.*/
libname out "&output_directory";

/* Store processed imputed data set in the output directory. The formatting is removed because this can cause issues when the data are opened in R or other software. 
We will later induce the missing values in an R script. 
*/
data out.simulated_full_data;
set joined_MI;
FORMAT _all_;
INFORMAT _all_;
run;

