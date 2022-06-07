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
quarter=qtr(date);
run;


/* obtain the ticker */

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


/*get the link table to merge optionmetrics and CRSP*/


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



/* combine weekends and holidays with the next market open date */


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
  select a.*, b.secid, b.cp_flag, b.volume, b.open_interest, b.permno, b.HCOMNAM, b.year, b.quarter
  from wsb_ticker3 as a left join option3 as b
  on a.date=b.date and a.tic=b.ticker
  order by date, tic;
quit;


data wsb_ticker5; set wsb_ticker4;
if secid=. then delete;
label volume=' ';
rename _posts=posts _score=score _num_comments=num_comments _awards=awards _posts=posts;
run;

proc sort data=wsb_ticker5;
by secid permno date;

proc print data=wsb_ticker5 (obs=100);
run;

/*convert the option daily data to quarterly data*/

proc summary data=wsb_ticker5;
by secid permno;
class date;
var score num_comments awards posts volume open_interest;
format date YYQ6.;
output out= wsb_ticker6 (drop= _type_ _freq_) sum= ;
run;

data wsb_ticker6; set wsb_ticker6;
if date=. then delete;
run;

proc print data=wsb_ticker6 (obs=200);
run;


/*distribution and correlation */

proc means data=wsb_ticker6 n mean std p25 p50 p75 max; 
    var  score num_comments awards posts volume;
run;

proc corr data=wsb_ticker6;
    var score num_comments awards posts volume;
run;

%include "/home/ou/lzhangg/macros/winsor.sas";
%winsor(dsetin=wsb_ticker6, dsetout=wsb_ticker6, byvar=none, 
        vars=score num_comments posts volume, type=winsor, pctl=1 99);

proc means data=wsb_ticker6 n mean std p25 p50 p75 max; 
    var  score num_comments awards posts volume;
run;

proc corr data=wsb_ticker6;
    var score num_comments awards posts volume;
run;

endrsubmit;




/*propensity score matching based on retail investor attention; using Da, Engelberg and Gao (2011) attention measures */

/*get quarterly firm characteristics*/

rsubmit;

data firmchar;
    set compd.fundq;
	where indfmt="INDL" and datafmt="STD" and consol="C";
    if 2001 < fyearq < 2022 ;
	if 6000 le sich le 6799 then delete;
	keep gvkey tic cusip fyearq datacqtr datafqtr apdedateq fyr rdq atq dlttq dlcq prccq cshoq saleq;
run;


 /* some firms' apdedateq is missing, generate the actual period end date for those firms*/

data quarterly; set firmchar;
if missing(apdedateq);
fqtr = substr(datafqtr,6,1);
fmonth=fqtr*3;
month=fmonth-(12-fyr);
if month le 0 then month=month+12;
fyear=substr(datafqtr,1,4);
if fyr le 5 and month le fyr then year=fyear+1;
else if fyr le 5 and month > fyr then year=fyear;
else if fyr >5 and month le fyr then year=fyear;
else if fyr >5 and month > fyr then year=fyear-1;
datadate = intnx('MONTH',mdy(month,25,year),0,'END');
format datadate yymmddn8.;
run;

data quarterly1; set quarterly;
drop apdedateq fqtr fmonth month fyear year;
rename datadate=apdedateq;
run;

data quarterly2; set firmchar;
if not missing(apdedateq);
run;

data firmchar1;set quarterly2 quarterly1;
run;

proc sort data=firmchar1;
by gvkey apdedateq;
run;

data firmchar1;set firmchar1;
Size=log(1+prccq*cshoq);
Leverage=(dlttq+dlcq)/atq;
/*Advertising_ratio=xad/salem1;*/
run;

data firmchar1;set firmchar1;
if missing(saleq) then delete;
if Size=. then Size=0;
if Leverage = . then Leverage = 0;
drop prccq cshoq saleq atq dlttq dlcq;
run;

proc print data=firmchar1 (obs=100);
run;

endrsubmit;


/* get advertising costs*/
rsubmit;

data advert;
    set compd.funda;
	where indfmt="INDL" and datafmt="STD" and consol="C" and curcd="USD";
    if 2001 < fyear < 2022 ;
	if 6000 le sich le 6799 then delete;
	keep gvkey cusip fyear datadate sich xad sale;
run;

proc sql;
    create table advert as
        select a.*, b.sale as salem1
        from advert as a left join advert as b
        on a.gvkey=b.gvkey and a.fyear-1=b.fyear;
quit;

data advert;set advert;
Advertising_ratio=xad/salem1;
run;

data advert;set advert;
if missing(salem1) then delete;
if Advertising_ratio=. then Advertising_ratio=0;
drop sale xad salem1;
run;

proc print data=advert (obs=100);
run;

proc sql;
  create table firmchar2 as
  select a.*, b.sich, b.Advertising_ratio
  from firmchar1 as a left join advert as b
  on a.gvkey=b.gvkey and a.fyearq=b.fyear;
quit;

data firmchar2;set firmchar2;
if missing(sich) then delete;
run;

proc print data=firmchar2 (obs=500);
run;

endrsubmit;

/* combine option data with firm characteristics */
rsubmit;

proc sql;
create table firmchar3 as
  select a.*, b.lpermno as permno
  from firmchar2 a left join crspa.ccmxpf_linktable b
  on not missing(a.gvkey) and a.gvkey=b.gvkey 
     and b.LINKPRIM in ('P', 'C')
     and b.LINKTYPE in ('LU', 'LC')
	 and not missing(apdedateq)
     and (b.LINKDT<=a.apdedateq or missing(b.LINKDT))
     and (a.apdedateq<=b.LINKENDDT or missing(b.LINKENDDT))
     group by a.gvkey, permno;
quit;


data firmchar3; set firmchar3;
datadate=input(datacqtr,YYQ6.);
format datadate YYQ6.;
informat datadate YYMMDD8.;
mergedate=qtr(datadate)||year(datadate);
run;

data wsb_ticker7; set wsb_ticker6;
mergedate=qtr(date)||year(date);
run;

proc sql;
  create table wsb_com as
  select a.*, b.cusip, b.gvkey, b.sich, b.Size, b.Leverage, b.Advertising_ratio
  from wsb_ticker7 as a left join firmchar3 as b
  on a.permno=b.permno and a.mergedate=b.mergedate;
quit;

data wsb_com; set wsb_com;
if missing(size) then delete;
run;

proc print data=wsb_com (obs=200);
run;

endrsubmit;


/* get analyst coverage data */

rsubmit;

data analys;
    set ibes.detu_epsus;
    if 2011 < year(FPEDATS) < 2022;
	keep ticker CUSIP OFTIC ANNDATS FPEDATS ANALYS;
run;

data analys; set analys;
mergedate=qtr(FPEDATS)||year(FPEDATS);
run;

/* count the number of analysts*/

proc sql;
    create table analys1 as
    select distinct ticker, CUSIP, OFTIC, count(ANALYS) as n_analys, mergedate
        from analys
        group by ticker, mergedate;
quit;


/* merge with option combined data*/

proc sql;
create table wsb_com
  as select a.*, b.ibtic
  from wsb_com a left join
      (select distinct gvkey, ibtic from comp.security
       where not missing(gvkey) and not missing(ibtic) and iid='01') b
  on a.gvkey=b.gvkey
  group by a.gvkey, mergedate
  order by a.gvkey, mergedate;
quit;


/*CRSP-IBES link table*/
%include "/home/ou/lzhangg/macros/_mycstlink.sas";
%ICLINK (IBESID=IBES.ID,CRSPID=CRSP.STOCKNAMES,OUTSET=ICLINK);
 
 /*which firms have permnos, but have no matching IBES ticker*/
data noticker; set wsb_com;
  where not missing(permno) and missing(ibtic);
  drop ibtic;
run;

/*link in additional IBES ticker-permno matches */ 
proc sort data=iclink (where=(score in (0,1,2))) out=ibeslink;
  by permno ticker score;
run;
 
data ibeslink; set ibeslink;
  by permno ticker; if first.permno;
run;
 
proc sql;
  create table noticker1
  as select a.*, b.ticker as ibtic
  from noticker a left join ibeslink b
  on a.permno=b.permno
  order by gvkey, mergedate;
quit;
 
data wsb_com;
  set wsb_com (where=(missing(permno) or not missing(ibtic))) noticker1;
  label ibtic='IBES Ticker';
run;

proc sql;
  create table wsb_com1 as
  select a.*, b.n_analys
  from wsb_com as a left join analys1 as b
  on a.ibtic=b.ticker and a.mergedate=b.mergedate;
quit;


data wsb_com1;set wsb_com1;
analycov=log(1+n_analys);
drop n_analys ibtic;
run;

proc sort data=wsb_com1 nodupkey;
by permno date;

data wsb_com1; set wsb_com1;
if missing(analycov) then analycov=0;
run;

proc print data=wsb_com1 (obs=200);
run;

endrsubmit;




/* obtain return data from crsp */

rsubmit;

data return;
    set crspa.msf;
    if 2011 < year(date) < 2022;
	keep ret cusip date permno;
run;

/* calculate abnormal return */

%include "/home/ou/lzhangg/macros/Event_study.sas";
%ABRET (inset=return, outset=results, datevar=date, retvar=ret, freq=m, window=6, step=1, min=2, model=FF);

proc sort data=results;
by permno date;
run;

proc summary data=results;
by permno;
class date;
var abnormal_ret;
format date YYQ6.;
output out= ret (drop= _type_ _freq_) mean= ;
run;

data ret; set ret;
if date=. then delete;
mergedate=qtr(date)||year(date);
run;

/* merge with option data*/

proc sql;
  create table wsb_com2 as
  select a.*, b.abnormal_ret
  from wsb_com1 as a left join ret as b
  on a.permno=b.permno and a.mergedate=b.mergedate;
quit;

proc print data=wsb_com2(obs=500);
run;

endrsubmit;


/* use propensity score matching around three dates to identify control groups */
/* the Robinhood mobile app is introduced in 2015, option trading is available on Robinhood at the end of 2017 */

rsubmit;

data wsb_com3; set wsb_com2;
trading_volume=log(1+volume);
if 2016<year(date)<2019;
run;


/* first create dummy variable that equals 1 if retail investor attention is above the industry median value */;


data wsb_com4;set wsb_com3;
sic2 = input(substr(put(sich,5.-l),1,2),2.);
run;

proc summary data=wsb_com4;
class sic2;
ways 1;
var posts;
output out=_medians_ median= /autoname;
run;

proc sql;
       create table wsb_com5
       as select a.*, posts_Median
       from wsb_com4 a left join _medians_ b
       on a.sic2=b.sic2;
quit; 

proc sql;
create table wsb_com5 as
select *,posts>posts_Median as Highpos
from wsb_com5
order by sich,date;
quit;

data wsb_com5; set wsb_com5;
if missing(posts_Median) then delete;
run;

%include "/home/ou/lzhangg/macros/winsor.sas";
%winsor(dsetin=wsb_com5, dsetout=wsb_com6, byvar=none, 
        vars=score num_comments posts Size Leverage analycov Advertising_ratio volume, type=winsor, pctl=1 99);

proc means data=wsb_com6 n mean std p25 p50 p75 max; 
var  score num_comments posts Size Leverage analycov Advertising_ratio volume;
run;

endrsubmit;



/*propensity score matching */
rsubmit;

ods graphics on;
proc psmatch data=wsb_com6 region=treated;
class Highpos mergedate;
psmodel Highpos(Treated='1')= analycov Advertising_ratio Size abnormal_ret;
match method=greedy(k=1) exact=mergedate caliper=0.1;
assess lps var=(Size Advertising_ratio analycov abnormal_ret) / plots=all weight=none;
output out(obs=all)=wsb_matched matchid=_MatchID;
run;


proc sort data=wsb_matched out=mydata.wsb_matched1;
by _PS_;
run;

data mydata.wsb_matched1; set mydata.wsb_matched1;
if _matchID=. then delete;
run;


/* descriptive statistics */

data wsb_treat; set mydata.wsb_matched1;
if highpos=1;
run;

data wsb_control; set mydata.wsb_matched1;
if highpos=0;
run;

proc means data=wsb_treat n mean std p25 p50 p75 max; 
var  score num_comments posts Size Leverage analycov Advertising_ratio volume;
run;

proc means data=wsb_control n mean std p25 p50 p75 max; 
var  score num_comments posts Size Leverage analycov Advertising_ratio volume;
run;

/* test the difference between treatment and control groups */
proc ttest data=mydata.wsb_matched1;
class highpos;
var Size Advertising_ratio analycov abnormal_ret trading_volume;
run;


/* define pre and post*/


data mydata.wsb_matchedq;set mydata.wsb_matched1;
if year(date)>2017 then post=1;
else post=0;
drop _PS_ _MATCHWGT_ _MatchID;
run;


proc print data=mydata.wsb_matchedq(obs=300);
run;


endrsubmit;
