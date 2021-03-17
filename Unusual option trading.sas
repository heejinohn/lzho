%macro signon_cloud;
    %let wrds=wrds-cloud.wharton.upenn.edu 4016;
    options comamid=TCP remote=WRDS;
    signon username=lzhangg pw="268746Zl!";
%mend signon_cloud;

%signon_cloud;

rsubmit;

options dlcreatedir;  
libname mydata "~/mydatasets";


/* obtain option trading volume from OptionMetrics */

data mydata.unoption;
    set optionm.opvold;
	if 2011 < year(date) < 2021;
	keep date secid open_interest cp_flag volume;
run;

/*only retain call options*/

data mydata.unoption; set mydata.unoption;
if cp_flag="C";
run;


data mydata.unoption; set mydata.unoption;
if open_interest=0 then delete;
if volume=0 then delete;
Year=year(date);
run;

proc print data=mydata.unoption (obs=100);
run;

endrsubmit;


/*get the link table to merge optionmetrics and CRSP*/

rsubmit;

data mydata.link;
    set wrdsapps.opcrsphist;
	keep permno secid sdate edate;
run;


/*some securityIDs have multiple permnos, choose those permnos the sample peroid falls in*/

data mydata.link; set mydata.link;
if year(edate) <2012 or year(sdate) >2019 then delete;
run;

proc print data=mydata.link (obs=100);
run;

endrsubmit;


/*merge option data with link table*/

rsubmit;

data mydata.link;set mydata.link;
run;

proc sql;
  create table mydata.unoption1 as
  select a.*, b.PERMNO
  from mydata.unoption as a left join mydata.link as b
  on a.secid=b.secid;
quit;

proc print data=mydata.unoption1 (obs=500);
run;

endrsubmit;


/*get CRSP company info*/

rsubmit;

data mydata.comn;
    set crspa.dsfhdr;
	keep cusip permno hcomnam;
run;

proc print data=mydata.comn (obs=100);
run;

endrsubmit;


/* merge options with CRSP company name info */

rsubmit;

proc sql;
  create table mydata.unoption2 as
  select a.*, b.hcomnam
  from mydata.unoption1 as a left join mydata.comn as b
  on a.PERMNO=b.PERMNO;
quit;

data mydata.unoption2; set mydata.unoption2;
if PERMNO=. then delete;
run;


proc sort data=mydata.unoption2;
by secid date;
run;


proc print data=mydata.unoption2 (obs=500);
run;

endrsubmit;


/* Calculate the moving average trading volume in 30 days */

rsubmit;

proc expand data=mydata.unoption2 out=mydata.unoption3;
     by secid;
     convert volume=sum30volume / METHOD = none TRANSFORMOUT = (movSum 30 trimleft 29);
run;

data mydata.unoption3; set mydata.unoption3;
avgvolume=round(sum30volume/30);
run;

proc print data=mydata.unoption3 (obs=500);
run;

endrsubmit;

/*identify unusual trading activity*/

rsubmit;

data mydata.unoption3; set mydata.unoption3;
if avgvolume=. then delete;
run;

data mydata.unoption3; set mydata.unoption3;
if volume>lag(avgvolume)*3; /*I define unusual option trading if the daily volume is greater than 200% of the last 30 days' average trading volume*/
run;

data mydata.unoption3; set mydata.unoption3;
keep secid date cp_flag volume hcomnam permno avgvolume;
run;

data mydata.unoption3; set mydata.unoption3; /*the first observation has no lagged value to compare, so delete it from the sample*/
by secid;
if first.secid then delete;
run;

proc print data=mydata.unoption3 (obs=500);
run;

endrsubmit;

