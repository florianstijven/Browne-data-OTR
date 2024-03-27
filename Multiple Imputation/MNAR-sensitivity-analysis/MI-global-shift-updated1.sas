/* Specify which directory contains the (processed) input data set. */
%let input_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/Multiple Imputation/Artificial Data for Illustrations;
/* Specify which directory is to be used for output, i.e., to save the imputed data sets in. */
%let output_directory = C:/Users/u0157247/Documents/Github repos/other repos/Browne-data-OTR/Multiple Imputation/MNAR-sensitivity-analysis;
/* Specify the number of imputations */
%let n_imputations = 20;
/* Specify the number of burn-in iterations. 
The default is 25, but it's better to err on the side of caution. So, a value larger than 25 is preferred. */
%let n_burnin = 100;
/* Define the shifts to consider in the MNAR scenarios. These shifts are on the logit scale. */
%let globalshifts=-10|-8|-6|-4|-3|-2|-1|0|1|2|3|4|6|8|10|12;

/* Set libref to the directory that contains the processed data set with missing values.*/
libname indata "&input_directory";

/* Specify file with formatting options. Without this file, the data set cannot be properly read and SAS will give errors. */
OPTIONS FMTSEARCH = (indata.formats);

/* Load data sets into the work library. */
data final;
set indata.final_updated1;
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

/* Compatible MI is performed. This is "compatible" imputation since the imputation is performed in each treatment group separately.
This imputation method is compatible with the goal of the further analyses which is essentially to find treatment effect heterogeneity.
All variables that correspond to scales with restrictions are transformed with a logistic transformation to the entire real line.
This ensures that all imputed values are consistent with their scale. 
For all imputations, logistic models are used for categorical variables. For phealth (ordinal variable), a cumulative logistic model is used. */

/* We start by transforming the scales to the [1, 101] interval.
This ensures that the following logistic transformation does not lead to infinite values. */
data final_transformed;
set final;
where group ^= 3;
madrsv1 = madrsv1*100/60 + 1; madrst2 = madrst2*100/60 + 1; madrst3 = madrst3*100/60 + 1; madrst4 = madrst4*100/60 + 1;
cesd = cesd*100/60 + 1; cesd2 = cesd2*100/60 + 1; cesd3 = cesd3*100/60 + 1; cesd4 = cesd4*100/60 + 1;
vas = vas + 1; vas2 = vas2 + 1; vas3 = vas3 + 1; vas4 = vas4 + 1;
sasb = (sasb - 1)*100/4 + 1; sasb2 = (sasb2 - 1)*100/4 + 1; sasb3 = (sasb3 - 1)*100/4 + 1; sasb4 = (sasb4 - 1)*100/4 + 1; 
famfun = (famfun - 1)*100/3 + 1;  famfun2 = (famfun2 - 1)*100/3 + 1; famfun3 = (famfun3 - 1)*100/3 + 1; famfun4 = (famfun4 - 1)*100/3 + 1;
run;

/* Check that all scales are in the [1, 101] interval */
proc means data=final_transformed nmiss min max mean;
	var _all_;
run;

/* Imputate under a set of MNAR scenarios defined by a constant shift in all treatment groups. */

/*This Loops thoough a set of variables where the variables
are separated by "|". Any other delimiter can be used
and specified in the scan function as well*/
 
%macro do_shift_impute(varlist);
%let i=1;
%do %while (%scan(&varlist, &i, |) ^=%str());
%let shift=%scan(&varlist, &i, |); 
%put &var;

/* Proc MI: For group = 1 */
proc mi data=final_transformed out=final_MI_1 nimpute=&n_imputations seed=1;		
	where group = 1;
	class sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var sex disorder phealth age
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
mnar adjust(cesd2 / shift=%sysevalf(&shift./10));
run;

/* Proc MI: For group = 2 */
proc mi data=final_transformed out=final_MI_2 nimpute=&n_imputations seed=2;		
	where group = 2;
	class sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var sex disorder phealth age
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
mnar adjust(cesd2 / shift=%sysevalf(&shift./10));
run;

/* The imputed data sets are joined into a single data set. */
data final_MI;
	set final_MI_1 final_MI_2;
run;

/* We transform the variables in the full imputed data set back to the original scale. */
data final_MI;
set final_MI;
madrsv1 = (madrsv1 - 1)*60/100; madrst2 = (madrst2 - 1)*60/100; madrst3 = (madrst3 - 1)*60/100; madrst4 = (madrst4 - 1)*60/100;
cesd = (cesd - 1)*60/100; cesd2 = (cesd2 - 1)*60/100; cesd3 = (cesd3 - 1)*60/100; cesd4 = (cesd4 - 1)*60/100;
vas = vas - 1; vas2 = vas2 - 1; vas3 = vas3 - 1; vas4 = vas4 - 1;
sasb = (sasb - 1)*4/100 + 1; sasb2 = (sasb2 - 1)*4/100 + 1; sasb3 = (sasb3 - 1)*4/100 + 1; sasb4 = (sasb4 - 1)*4/100 + 1; 
famfun = (famfun - 1)*3/100 + 1;  famfun2 = (famfun2 - 1)*3/100 + 1; famfun3 = (famfun3 - 1)*3/100 + 1; famfun4 = (famfun4 - 1)*3/100 + 1;
run;


/* The data set are sorted by imputation number. This is important for some methods. */
proc sort data=final_MI;
	by _imputation_;
run;

/* Further post-processing to ensure that the scale restrictions are satisfied for all imputed values. */
data final_MI;
set final_MI;
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

/* Add extra variable indicating the shift that was used. This variable indicates the MNAR scenario in the final data set. */
data final_MI;
set final_MI;
shift = %sysevalf(&shift./10);
run;

%if &shift=-10 %then %do;
              		data final_MI_global; 
			   			set final_MI;
					run;
            %end;
         %else %do;
               data final_MI_global;
			   		set final_MI_global final_MI;
				run;
            %end;
 
*Increment counter;
%let i=%eval(&i+1);
%end;
%mend DO_SHIFT_IMPUTE;

%do_shift_impute(&globalshifts);

/* Set libref to directory in which to save the imputed data sets.*/
libname out "&output_directory";

/* Store processed imputed data set in the output directory. The formatting is removed because this can cause issues when the data are opened in R or other software. */
data out.final_MI_global_updated1;
set final_MI_global;
FORMAT _all_;
INFORMAT _all_;
run;
