/* Specify which directory contains the (processed) input data set. */
%let input_directory = C:\Users\u0157247\OneDrive - KU Leuven\Phd\Hulp Trung Dung\Browne-code\Multiple Imputation\Artificial Data for Illustrations;
/* Specify which directory is to be used for output, i.e., to save the imputed data sets in. */
%let output_directory = C:\Users\u0157247\OneDrive - KU Leuven\Phd\Hulp Trung Dung\Browne-code\Multiple Imputation\Artificial Data for Illustrations;
/* Specify the number of imputations */
%let n_imputations = 40;
/* Specify the number of burn-in iterations. 
The default is 25, but it's better to err on the side of caution. So, a value larger than 25 is preferred. */
%let n_burnin = 100;

/* Set libref to the directory that contains the processed data set with missing values.*/
libname indata "&input_directory";

/* Specify file with formatting options. Without this file, the data set cannot be properly read and SAS will give errors. */
OPTIONS FMTSEARCH = (indata.formats);

/* Load data sets into the work library. */
data final_updated1;
set indata.final_updated1;
run;

proc means data=final_updated1 nmiss min max;
run;

data final_updated2;
set indata.final_updated2;
run;

proc means data=final_updated2 nmiss min max;
run;

data final_updated3;
set indata.final_updated3;
run;

proc means data=final_updated3 nmiss min max;
run;


/* All variables that correspond to scales with restrictions are transformed with a logistic transformation to the entire real line.
This ensures that all imputed values are consistent with their scale. 
For all imputations, logistic models are used for categorical variables. For phealth (ordinal variable), a cumulative logistic model is used. */

/* We start by transforming the scales to the [1, 101] interval.
This ensures that the following logistic transformation does not lead to infinite values. */
data final_updated_transformed1;
set final_updated1;
madrsv1 = madrsv1*100/60 + 1; madrst2 = madrst2*100/60 + 1; madrst3 = madrst3*100/60 + 1; madrst4 = madrst4*100/60 + 1;
cesd = cesd*100/60 + 1; cesd2 = cesd2*100/60 + 1; cesd3 = cesd3*100/60 + 1; cesd4 = cesd4*100/60 + 1;
vas = vas + 1; vas2 = vas2 + 1; vas3 = vas3 + 1; vas4 = vas4 + 1;
sasb = (sasb - 1)*100/4 + 1; sasb2 = (sasb2 - 1)*100/4 + 1; sasb3 = (sasb3 - 1)*100/4 + 1; sasb4 = (sasb4 - 1)*100/4 + 1; 
famfun = (famfun - 1)*100/3 + 1;  famfun2 = (famfun2 - 1)*100/3 + 1; famfun3 = (famfun3 - 1)*100/3 + 1; famfun4 = (famfun4 - 1)*100/3 + 1;
run;

data final_updated_transformed2;
set final_updated2;
madrsv1 = madrsv1*100/60 + 1; madrst2 = madrst2*100/60 + 1; madrst3 = madrst3*100/60 + 1; madrst4 = madrst4*100/60 + 1;
cesd = cesd*100/60 + 1; cesd2 = cesd2*100/60 + 1; cesd3 = cesd3*100/60 + 1; cesd4 = cesd4*100/60 + 1;
vas = vas + 1; vas2 = vas2 + 1; vas3 = vas3 + 1; vas4 = vas4 + 1;
sasb = (sasb - 1)*100/4 + 1; sasb2 = (sasb2 - 1)*100/4 + 1; sasb3 = (sasb3 - 1)*100/4 + 1; sasb4 = (sasb4 - 1)*100/4 + 1; 
famfun = (famfun - 1)*100/3 + 1;  famfun2 = (famfun2 - 1)*100/3 + 1; famfun3 = (famfun3 - 1)*100/3 + 1; famfun4 = (famfun4 - 1)*100/3 + 1;
run;

data final_updated_transformed3;
set final_updated3;
madrsv1 = madrsv1*100/60 + 1; madrst2 = madrst2*100/60 + 1; madrst3 = madrst3*100/60 + 1; madrst4 = madrst4*100/60 + 1;
cesd = cesd*100/60 + 1; cesd2 = cesd2*100/60 + 1; cesd3 = cesd3*100/60 + 1; cesd4 = cesd4*100/60 + 1;
vas = vas + 1; vas2 = vas2 + 1; vas3 = vas3 + 1; vas4 = vas4 + 1;
sasb = (sasb - 1)*100/4 + 1; sasb2 = (sasb2 - 1)*100/4 + 1; sasb3 = (sasb3 - 1)*100/4 + 1; sasb4 = (sasb4 - 1)*100/4 + 1; 
famfun = (famfun - 1)*100/3 + 1;  famfun2 = (famfun2 - 1)*100/3 + 1; famfun3 = (famfun3 - 1)*100/3 + 1; famfun4 = (famfun4 - 1)*100/3 + 1;
run;

/* Proc MI: For all groups together */
ods graphics on;
proc mi data=final_updated_transformed1 out=final_MI_incompatible1 nimpute=&n_imputations seed=1;		
	class group sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var group sex disorder phealth age numchild
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
	  famfun famfun2 famfun3 famfun4 / c = 102) 
log(numchild / c = 0.5);
run;
ods graphics off;

ods graphics on;
proc mi data=final_updated_transformed2 out=final_MI_incompatible2 nimpute=&n_imputations seed=1;		
	class group sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var group sex disorder phealth age numchild
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
	  famfun famfun2 famfun3 famfun4 / c = 102) 
log(numchild / c = 0.5);
run;
ods graphics off;

ods graphics on;
proc mi data=final_updated_transformed3 out=final_MI_incompatible3 nimpute=&n_imputations seed=1;		
	class group sex disorder phealth;
	fcs nbiter=&n_burnin plots=trace reg() logistic() logistic(disorder/link=glogit);
	var group sex disorder phealth age numchild
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
	  famfun famfun2 famfun3 famfun4 / c = 102) 
log(numchild / c = 0.5);
run;
ods graphics off;


/* We transform the variables in the full imputed data set back to the original scale. */
data final_MI_incompatible1;
set final_MI_incompatible1;
madrsv1 = (madrsv1 - 1)*60/100; madrst2 = (madrst2 - 1)*60/100; madrst3 = (madrst3 - 1)*60/100; madrst4 = (madrst4 - 1)*60/100;
cesd = (cesd - 1)*60/100; cesd2 = (cesd2 - 1)*60/100; cesd3 = (cesd3 - 1)*60/100; cesd4 = (cesd4 - 1)*60/100;
vas = vas - 1; vas2 = vas2 - 1; vas3 = vas3 - 1; vas4 = vas4 - 1;
sasb = (sasb - 1)*4/100 + 1; sasb2 = (sasb2 - 1)*4/100 + 1; sasb3 = (sasb3 - 1)*4/100 + 1; sasb4 = (sasb4 - 1)*4/100 + 1; 
famfun = (famfun - 1)*3/100 + 1;  famfun2 = (famfun2 - 1)*3/100 + 1; famfun3 = (famfun3 - 1)*3/100 + 1; famfun4 = (famfun4 - 1)*3/100 + 1;
run;

data final_MI_incompatible2;
set final_MI_incompatible2;
madrsv1 = (madrsv1 - 1)*60/100; madrst2 = (madrst2 - 1)*60/100; madrst3 = (madrst3 - 1)*60/100; madrst4 = (madrst4 - 1)*60/100;
cesd = (cesd - 1)*60/100; cesd2 = (cesd2 - 1)*60/100; cesd3 = (cesd3 - 1)*60/100; cesd4 = (cesd4 - 1)*60/100;
vas = vas - 1; vas2 = vas2 - 1; vas3 = vas3 - 1; vas4 = vas4 - 1;
sasb = (sasb - 1)*4/100 + 1; sasb2 = (sasb2 - 1)*4/100 + 1; sasb3 = (sasb3 - 1)*4/100 + 1; sasb4 = (sasb4 - 1)*4/100 + 1; 
famfun = (famfun - 1)*3/100 + 1;  famfun2 = (famfun2 - 1)*3/100 + 1; famfun3 = (famfun3 - 1)*3/100 + 1; famfun4 = (famfun4 - 1)*3/100 + 1;
run;

data final_MI_incompatible3;
set final_MI_incompatible3;
madrsv1 = (madrsv1 - 1)*60/100; madrst2 = (madrst2 - 1)*60/100; madrst3 = (madrst3 - 1)*60/100; madrst4 = (madrst4 - 1)*60/100;
cesd = (cesd - 1)*60/100; cesd2 = (cesd2 - 1)*60/100; cesd3 = (cesd3 - 1)*60/100; cesd4 = (cesd4 - 1)*60/100;
vas = vas - 1; vas2 = vas2 - 1; vas3 = vas3 - 1; vas4 = vas4 - 1;
sasb = (sasb - 1)*4/100 + 1; sasb2 = (sasb2 - 1)*4/100 + 1; sasb3 = (sasb3 - 1)*4/100 + 1; sasb4 = (sasb4 - 1)*4/100 + 1; 
famfun = (famfun - 1)*3/100 + 1;  famfun2 = (famfun2 - 1)*3/100 + 1; famfun3 = (famfun3 - 1)*3/100 + 1; famfun4 = (famfun4 - 1)*3/100 + 1;
run;


/* The data set are sorted by imputation number. This is important for some methods. */
proc sort data=final_MI_incompatible1;
	by _imputation_;
run;

proc sort data=final_MI_incompatible2;
	by _imputation_;
run;

proc sort data=final_MI_incompatible3;
	by _imputation_;
run;


/* Further post-processing to ensure that the scale restrictions are satisfied for all imputed values. */
data final_MI_incompatible1;
set final_MI_incompatible1;
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

numchild = round(numchild, 1);
run;

data final_MI_incompatible2;
set final_MI_incompatible2;
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

numchild = round(numchild, 1);
run;

data final_MI_incompatible3;
set final_MI_incompatible3;
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

numchild = round(numchild, 1);
run;

/* Set libref to directory in which to save the imputed data sets.*/
libname out "&output_directory";

/* Store processed imputed data set in the output directory. The formatting is removed because this can cause issues when the data are opened in R or other software. */
data out.final_MI_updated1_global;
set final_MI_incompatible1;
FORMAT _all_;
INFORMAT _all_;
run;

data out.final_MI_updated2_global;
set final_MI_incompatible2;
FORMAT _all_;
INFORMAT _all_;
run;

data out.final_MI_updated3_global;
set final_MI_incompatible3;
FORMAT _all_;
INFORMAT _all_;
run;
