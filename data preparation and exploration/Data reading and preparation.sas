/* Specify which directory is to be used for output. */
%let output_directory = C:/Users/u0157247/OneDrive - KU Leuven/Phd/Hulp Trung Dung/Browne-code/data preparation and exploration;
/* Specify which directory contains the original input data sets. */
%let input_directory = C:/Users/u0157247/OneDrive - KU Leuven/Phd/Hulp Trung Dung/DATA/;

/* Specify libref to indicate where to store the processed data file. */
libname out "&output_directory";

/* The formats file is also saved in the same location as the sas data set. This formats file is required to read the sas data set.*/
PROC FORMAT LIBRARY=out;
run;
/* Use formats file that was created before. Without this formats file, SAS will run into errors. */
OPTIONS FMTSEARCH = (out.formats);
run;


/* Reading data */
/* Note: .sav files below are stored in the server at ru.nl */


/* lotsofzots */
proc import out=lotsofzots
  datafile = "&input_directory.lotsofzots.sav"
  dbms = SAV replace;
  fmtlib = FORMATS;
run;
/*
ERROR: Invalid Operation.
ERROR: Termination due to Floating Point Exception
*/

proc contents data=lotsofzots;
run;


/* MADT1234 */
proc import out=MADT1234
  datafile = "&input_directory.MADT1234.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;
/* The above data are loaded for completeness, although they will not be used further on because these
data only contain patients with no missing values. 
The data that will be loaded next contain the same information is the data above. */

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from MADT1234;
quit;
/* 525 */

/* Variables */
proc contents data=MADT1234;
run;

/* IPD: This data set contains measurements at baseline and additional baseline covariates. */
proc import out=IDP
  datafile = "&input_directory.ZOT1 changed for IPD.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from IDP
	group by group;
quit;
/* 707 */


proc sort data=IDP;
by group;
run; 
proc means data=IDP;
by group;
run;

/* Variables */
proc contents data=IDP;
run;


/* ZOT1: This data set contains the baseline outcome measures. In fact, these data contain much
overlapping information with the IDP data set. */
proc import out=ZOT1
  datafile = "&input_directory.ZOT1.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from ZOT1;
quit;
/* 707 */

/* Variables */
proc contents data=ZOT1;
run;

/* ZOT2: This data set contains the outcome measures at 6 months. */
proc import out=ZOT2
  datafile = "&input_directory.ZOT2.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from ZOT2;
quit;
/* 586 */

/* Variables */
proc contents data=ZOT2;
run;

/* ZOT3: This data set contains the outcome measures at 1 year. */
proc import out=ZOT3
  datafile = "&input_directory.ZOT3.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from ZOT3;
quit;
/* 550; This should be 549 from what is given in the Browne paper. However, there is one observation with all missing data for the third measurement occasion. 
So it's rather an issue with the data organization than with the data themselves. */

proc sql;
SELECT *
FROM
    ZOT3
INNER JOIN
    IDP
ON
    ZOT3.id = IDP.id
WHERE i3done ^= 1;
quit;
/* Patient with id 51546 is present in "third" data set, but should not be there according to i3done. 
This means that we actually have 549 "observed" patients at the third time point.*/


/* Variables */
proc contents data=ZOT3;
run;

/* ZOT4: This data set contains the outcomes measures at 2 years. */
proc import out=ZOT4
  datafile = "&input_directory.ZOT4.sav"
  dbms = SAV replace;
  fmtlib = out.FORMATS;
run;

/* How many distinct IDs */
proc sql;
    select count(distinct id) as distinct_ids
    from ZOT4;
quit;
/* 525 */

/* Variables */
proc contents data=ZOT4;
run;

/***********************************************
Dataset	No of Obs	No of var	No of ID
lotsofzots		58	
MADT1234	525	6	525
IDP	707	82	707
ZOT1	707	81	707
ZOT2	586	59	586
ZOT3	550	56	550
ZOT4	525	56	525

***********************************************/

proc print data=IDP (obs=10);
run;

proc print data=ZOT1 (obs=10);
run;
/*Except age, the variables are the same for these datasets. In fact, the second data set contains the 
birth date. So, age can in principle be derived from the second one. We proceed with the IDP data instead
of the ZOT1 data. */

/* Join all four data sets on id. */
data browne;
	merge idp zot2 zot3 zot4;
	by id;
run;

/* Check Table 1 of the Browne paper. These are the number of patients that have completed 6 months of 
follow up in each treatment group. */
proc freq data=browne;
	where madrst2 ^=.;
	table group;
run;

/* Check who done first time point (baseline). 44 patients were randomized, but did not receive any treatment and follow up.*/
proc freq data=browne;
	table i1done;
run;

/* How does i1done (dropout immediately after randomization and before receiving treatment) vary across groups? */
proc freq data=browne;
	table i1done * group;
run;

/* Check who did second time point. From the paper, 59 patients started clinical visits but were unavailable at 6-month follow-up, and 18 patients
started treatment but did not complete any clinical follow-up during the first few months. */
proc freq data=browne;
	table i2done;
run;

/* Check who did third time point. From the paper, 37 more were unavailable for outcome measures at 1 year. 
This is not consistent with the data here.  */
proc freq data=browne;
	table i3done;
run;

/* Check who did fourth time point. From the paper, 24 more were unavailable at two years. 
This is again not consistent with the data here. */
proc freq data=browne;
	table i4done;
run;

/* The above two tables show that i3done and i4done are not consistent with the Browne paper. Still, the numbers of observed patients
are consistent with the paper. The difference lies in the indicators for patients that dropped out. For some of the latter patients, 
a separate missingness indicator is present, for the other, a missing value is present. This likely indicates that for some of the missing
patients, the reason for dropout is known. For others, the reasons are not known and a missing value is present in i3done and/or i4done. */


/* The browne data file contains many (sensitive) variables that are not needed for the further analyses. We therefore only
retain the variables that will be used in further analyses. In addition, the 44 patient that did not complete any visits nor received any
treatment will be left out. */
data subset;
	set browne;
	*Keep only patients that received any treatment.;
	where i1done = 1;
	keep id group sex age disorder numchild phealth
		madrsv1 sasb famfun cesd vas
		madrst2 sasb2 famfun2 cesd2 vas2
		madrst3 sasb3 famfun3 cesd3 vas3
		madrst4 sasb4 famfun4 cesd4 vas4;
run;

data final;
	retain id group sex age disorder numchild phealth
		madrsv1 sasb famfun cesd vas
		madrst2 sasb2 famfun2 cesd2 vas2
		madrst3 sasb3 famfun3 cesd3 vas3
		madrst4 sasb4 famfun4 cesd4 vas4;
	set subset;
run;

/* Reproduce some of the results in the Browne paper to validate the data processing. */
data finalchangescore;
set final;
famfundiff = famfun - famfun2;
madrsdiff = madrsv1 - madrst2;
madrsdiff4 = madrsv1 - madrst4;
sasdiff = sasb - sasb2;
run;

proc sort data=finalchangescore;
by group;
run;

/* Reproduce the means reported in Table 1 from the Browne paper. This table only uses patients that completed
the six months follow up. Only the means of age cannot be reproduced exactly. The difference between the reported
means and the computed means is 0.5 in both groups. Hence, this difference can be explained by the way age was defined.*/
proc means data=finalchangescore;
var madrsv1 sasb famfun age;
by group;
where madrst2^=.;
run;


/* Reproduce the means reported in Table 3 and in Section 6.4 from the Browne paper.*/
proc means data=finalchangescore;
var madrst2 famfundiff madrsdiff madrsdiff4 sasdiff;
by group;
run;


/* There is an issue with the vas scale. Values from this scale should be restricted to [0, 100]. 
However, there are a few observations where the vas value is larger than 100. Such values are converted to 100. */
proc means data=final min max;
var vas vas2 vas3 vas4;
run;

data final;
set final;
if (100 < vas < 105) then vas = 100;
if (100 < vas2 < 105) then vas2 = 100;
if (100 < vas3 < 105) then vas3 = 100;
if (100 < vas4 < 105) then vas4 = 100;
run;


/* Check the first 10 rows of this newly created data set. */
proc print data=final (obs=10);
run;

/* Output the newly created data set that only contains the variables that will be used further on. */
data out.final;
set final;
run;
