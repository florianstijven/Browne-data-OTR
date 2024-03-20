/* Specify which directory contains the (processed) input data set. */
%let input_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/data preparation and exploration;
/* Specify which directory is to be used for output, i.e., to save the updated data sets in. */
%let output_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/Multiple Imputation/Artificial Data for Illustrations;

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

/* Update 1: add interaction effect for cesd and past MDD. */ 
data final_update1;
set final;
if cesd2 ^= . then
	do; 
		if group = 2 then 
			do;
				cesd2 = cesd2 - 0.30 * (cesd - 40);
				if disorder = 2 or disorder = 4 then 
					cesd2 = cesd2 - 6;
			end;
		cesd2 = cesd2 + 0.20 * (cesd - 40);
		if disorder = 2 or disorder = 4 then 
					cesd2 = cesd2 + 4;
		/* We don't want to change values outside of the range of CESD. If this would happen, we change the values to the boundary value. */ 
		if cesd2 < 0 then cesd2 = 0;
		if cesd2 > 60 then cesd2 = 60;
	end;
run;

/* Set libref to directory in which to save the artifically updated data sets.*/
libname out "&output_directory";

/* Store the updated data sets. The formatting is removed because this can cause issues when the data are opened in R or other software. */
data out.final_updated1;
set final_update1;
FORMAT _all_;
INFORMAT _all_;
run;

