%signon_cloud;

rsubmit;

options dlcreatedir;  
libname mydata "~/mydatasets";


/* obtain option trading volume from OptionMetrics */

data option;
    set optionm.opvold;
	if 2011 < year(date) < 2022;
	keep date secid open_interest cp_flag volume;
run;

/*only retain call options*/

data option; set option;
if cp_flag="C";
run;


data option; set option;
if open_interest=0 then delete;
if volume=0 then delete;
Year=year(date);
run;

proc print data=option (obs=100);
run;

endrsubmit;


/* obtain the ticker */
rsubmit;

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
	create table option1 as
	select a.*, b.ticker
	from option as a left join ticker as b
	on a.secid = b.secid and fdate <= date  and date <= ldate;
quit;

proc sort data=option1 nodupkey;
	by secid date;
run;

proc print data=option1 (obs=100);
run;

endrsubmit;

/*get the link table to merge optionmetrics and CRSP*/

rsubmit;

data link;
    set wrdsapps.opcrsphist;
	keep permno secid sdate edate;
run;

/*some securityIDs have multiple permnos, choose those permnos the sample peroid falls in*/

data link; set link;
if year(edate) <2012 or year(sdate) >2019 then delete;
run;


/*merge option data with link table*/

proc sql;
  create table option2 as
  select a.*, b.PERMNO
  from option1 as a left join link as b
  on a.secid=b.secid;
quit;


/*get CRSP company info*/

data company;
    set crspa.dsfhdr;
	keep cusip permno hcomnam;
run;

/* merge options with CRSP company name info */

proc sql;
  create table option3 as
  select a.*, b.hcomnam
  from option2 as a left join company as b
  on a.PERMNO=b.PERMNO;
quit;

data option3; set option3;
if PERMNO=. then delete;
run;

proc sort data=option3;
by secid date;
run;

/*data option3; set option3;
if ticker="CQB";
run;*/

proc print data=option3 (obs=100);
run;

endrsubmit;


/*import the Reddit data */

rsubmit;

libname library xlsx "~/mydatasets/wsb_ticker.xlsx";

data wsb_ticker;set library."wsb_ticker"n;
run;

/*merge with wsb_ticker table*/

data wsb_ticker1; set wsb_ticker;
format date date9.;
informat date yymmdd8.;
run;


/* obtain the date from optionmetrics */

proc sql;
     create table opdate as
	 select distinct date as opdate
	 from optionm.opvold
	 where 2011 < year(date) < 2022;
quit;

/*merge it with Reddit data */

proc sql;
  create table wsb_ticker1 as
  select a.*, b.opdate
  from wsb_ticker1 as a left join opdate as b
  on a.date=b.opdate;
quit;

proc print data=wsb_ticker1 (obs=500);
run;

endrsubmit;

/* combine weekends and holidays with the next market open date */

rsubmit;

data wsb_ticker2;
 do _n_=1 by 1 until (not missing(opdate));
 set wsb_ticker1;
 by date;
end;

_date=date;

do _n_ = 1 to _n_;
    set wsb_ticker1;
    date = _date;
    output;
  end;

  drop _date;
run;

proc sort data=wsb_ticker2;
by date tic;

data wsb_ticker3; set wsb_ticker2;
by date tic;
retain _score _num_comments _awards _posts;
  if first.tic then do; 
  _score=score;
  _num_comments=num_comments;
  _awards=awards;
  _posts=posts;
  end;
  else do;
  _score+score;
  _num_comments+num_comments;
  _awards+awards;
  _posts+posts;
  end;
if last.tic;
drop opdate score num_comments awards posts;
run;

proc print data=wsb_ticker3 (obs=200);
run;

endrsubmit;

/* merge with option data */

rsubmit;

proc sql;
  create table wsb_ticker4 as
  select a.*, b.secid, b.cp_flag, b.volume, b.open_interest, b.permno, b.HCOMNAM
  from wsb_ticker3 as a left join option3 as b
  on a.date=b.date and a.tic=b.ticker
  order by date, tic;
quit;


data mydata.wsb_ticker5; set wsb_ticker4;
if secid=. then delete;
label volume=' ';
rename _posts=posts _score=score _num_comments=num_comments _awards=awards _posts=posts;
run;

proc print data=mydata.wsb_ticker5 (obs=200);
run;

proc means data=mydata.wsb_ticker5 n mean std p25 p50 p75 max; 
    var  score num_comments awards posts volume;
run;

proc corr data=mydata.wsb_ticker5;
    var score num_comments awards posts volume;
run;

%include "/home/ou/lzhangg/macros/winsor.sas";
%winsor(dsetin=mydata.wsb_ticker5, dsetout=mydata.wsb_ticker6, byvar=none, 
        vars=score num_comments posts volume, type=winsor, pctl=1 99);

proc means data=mydata.wsb_ticker6 n mean std p25 p50 p75 max; 
    var  score num_comments awards posts volume;
run;

proc corr data=mydata.wsb_ticker6;
    var score num_comments awards posts volume;
run;

proc univariate data=mydata.wsb_ticker5;
   var posts num_comments score;
   histogram;
run;

endrsubmit;
