options dlcreatedir;  
libname mydata "~";


/* obtain option trading volume from OptionMetrics */

data unoption;
    set optionm.opvold;
	if 2011 < year(date) < 2021;
	keep date secid ticker open_interest cp_flag volume;
run;

/*only retain call options*/

data unoption; set unoption;
if cp_flag="C";
run;


data unoption; set unoption;
if open_interest=0 then delete;
if volume=0 then delete;
Year=year(date);
run;

/*get the link table to merge optionmetrics and CRSP*/

data link;
    set wrdsapps.opcrsphist;
	keep permno secid sdate edate;
run;


/*some securityIDs have multiple permnos, choose those permnos the sample peroid falls in*/

data link; set link;
if year(edate) <2012 or year(sdate) >2019 then delete;
run;

proc print data=link (obs=100);
run;

/*merge option data with link table*/

data link;set link;
run;

proc sql;
  create table unoption1 as
  select a.*, b.PERMNO
  from unoption as a left join link as b
  on a.secid=b.secid;
quit;

proc print data=unoption1 (obs=500);
run;


/*get CRSP company info*/

data comn;
    set crspa.dsfhdr;
	keep cusip permno hcomnam;
run;

proc print data=comn (obs=100);
run;


/* merge options with CRSP company name info */

proc sql;
  create table unoption2 as
  select a.*, b.hcomnam
  from unoption1 as a left join comn as b
  on a.PERMNO=b.PERMNO;
quit;

data unoption2; set unoption2;
if PERMNO=. then delete;
run;


proc sort data=unoption2;
by secid date;
run;


proc print data=unoption2 (obs=500);
run;


/* Calculate the moving average trading volume in 30 days */

proc expand data=unoption2 out=unoption3;
     by secid;
     convert volume=sum30volume / METHOD = none TRANSFORMOUT = (movSum 30 trimleft 29);
run;

data unoption3; set unoption3;
avgvolume=round(sum30volume/30);
run;

proc print data=unoption3 (obs=500);
run;

/*identify unusual trading activity*/

data unoption3; set unoption3;
if avgvolume=. then delete;
run;

data unoption3; set unoption3;
if volume>lag(avgvolume)*3; /*I define unusual option trading if the daily volume is greater than 200% of the last 30 days' average trading volume*/
run;

data unoption3; set unoption3;
keep secid date cp_flag volume hcomnam permno avgvolume;
run;

data unoption3; set unoption3; /*the first observation has no lagged value to compare, so delete it from the sample*/
by secid;
if first.secid then delete;
run;

/******* GRAB TICKER FROM SECNMD *********/
proc sql;
  create table ticker
  as select *, min(effect_date) as fdate, max(effect_date) as ldate
  from optionm.secnmd
  group by secid, ticker
  order by secid, ticker, effect_date;
quit;

/* Label date range variables and keep only most recent company name */
data ticker;
  set ticker;
  by secid ticker;
  if last.ticker;
  label fdate="First Start date of OFTIC record";
  label ldate="Last Start date of OFTIC record";
  format fdate ldate date9.;
  drop effect_date;
run;

proc sql;
	create table option_ticker as
	select a.*, b.ticker
	from unoption3 a, ticker b
	where a.secid = b.secid and fdate <= date  and
		date <= ldate;
quit;

proc sort data=option_ticker out=mydata.option_ticker nodupkey;
	by secid date;
run;
