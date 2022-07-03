%signon_cloud;

rsubmit;

options dlcreatedir;  
libname mydata "~/mydatasets";


/*import the granger test result*/

libname library xlsx "~/mydatasets/granger_yearq.xlsx";

data granger;set library."Sheet1"n;
run;

data granger;set granger;
format yearq YYQ6.;
if (lead="activity" and lags="score") or (lead="score" and lags="activity");
if p<0.05 then sig=1;
else sig=0;
if sig=. then delete;
if p=. then delete;
date=qtr(yearq)||year(yearq);
run;

proc print data=granger (obs=100);
run;

endrsubmit;


/* import the Google search data*/

rsubmit;

libname library xlsx "~/mydatasets/Google_search_reshaped.xlsx";

data google;set library."Sheet1"n;
run;

/* convert the weekly data to quarterly data*/

proc sort data=google;
by ticker;
run;

proc summary data=google;
by ticker;
class date;
var volume;
format date YYQ6.;
output out= google1 (drop= _type_ _freq_) mean= ;
run;

data google1;set google1;
if missing(date) then delete;
gdate=qtr(date)||year(date);
run;

/*merge granger test results with google search data*/

proc sql;
  create table granger_merged as
  select a.*, b.volume
  from granger as a left join google1 as b
  on a.ticker=b.ticker and a.date=b.gdate;
quit;

proc sort data=granger_merged;
by ticker date;
run;

data granger_merged;set granger_merged;
drop yearq chi2 df p;
rename volume=google_volume;
run;


proc print data=granger_merged (obs=200);
run;

endrsubmit;


/* obtain permno */

/*proc sql;
  create table granger_merged as
  select a.*, b.permno
  from granger_merged as a left join crspa.dsfhdr as b
  on a.ticker=b.htick;
quit;

data granger_merged; set granger_merged;
if not missing(permno);
run;*/



/* obtain crsp permnos*/

rsubmit;

data iclink;
    set wrdsapps.ibcrsphist;
	if year(edate) <2018 or year(sdate) >2020 then delete;
run;

data stocknames; set crsp.stocknames;
keep permno ncusip namedt nameenddt ticker comnam;
rename ticker=crspticker;
run;

proc sql;
  create table iclink1 as
  select a.*, b.comnam, b.crspticker
  from iclink as a left join stocknames as b
  on a.permno=b.permno and a.ncusip=b.ncusip;
quit;

proc sort data=iclink1 nodupkey;
by ticker permno ncusip;
run;

proc sql;
  create table granger_merged1 as
  select a.*, b.permno, b.ncusip, b.score, b.comnam
  from granger_merged as a left join iclink1 as b
  on a.ticker=b.crspticker;
quit;

proc sort data=granger_merged1 nodupkey;
by ticker date lead lags;
run;

data granger_merged1;set granger_merged1;
if missing(permno) then delete;
run;

proc print data=granger_merged1 (obs=200);
run;

endrsubmit;




/*get variables related to retail investor attention; using Da, Engelberg and Gao (2011) attention measures */

/*get quarterly market capitalization data*/

rsubmit;

data firmchar;
    set compd.fundq;
	where indfmt="INDL" and datafmt="STD" and consol="C";
    if 2017 < fyearq < 2022 ;
	if 6000 le sich le 6799 then delete;
	keep gvkey tic cusip fyearq datacqtr datafqtr apdedateq fyr prccq cshoq saleq;
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
run;

data firmchar1;set firmchar1;
if Size=. then Size=0;
drop prccq cshoq saleq;
run;

proc print data=firmchar1 (obs=100);
run;

endrsubmit;


/* combine granger-causality results with firm market value */

rsubmit;

proc sql;
create table firmchar2 as
  select a.*, b.lpermno as permno
  from firmchar1 a left join crspa.ccmxpf_linktable b
  on not missing(a.gvkey) and a.gvkey=b.gvkey 
     and b.LINKPRIM in ('P', 'C')
     and b.LINKTYPE in ('LU', 'LC')
	 and not missing(apdedateq)
     and (b.LINKDT<=a.apdedateq or missing(b.LINKDT))
     and (a.apdedateq<=b.LINKENDDT or missing(b.LINKENDDT))
     group by a.gvkey, permno;
quit;


data firmchar2; set firmchar2;
datadate=input(datacqtr,YYQ6.);
format datadate YYQ6.;
informat datadate YYMMDD8.;
mergedate=qtr(datadate)||year(datadate);
run;

proc sql;
  create table granger_merged2 as
  select a.*, b.cusip, b.gvkey, b.Size
  from granger_merged1 as a left join firmchar2 as b
  on a.ticker=b.tic and a.date=b.mergedate;
quit;

data granger_merged1;set granger_merged2;
if missing(Size) then delete;
run;

proc print data=granger_merged2 (obs=200);
run;

endrsubmit;


/* get analyst coverage data */

rsubmit;


data analys;
    set ibes.detu_epsus;
    if 2017 < year(FPEDATS) < 2022 and fpi=6;
	keep ticker CUSIP OFTIC ANNDATS FPEDATS ANALYS;
run;

data analys; set analys;
mergedate=qtr(anndats)||year(anndats);
run;

/* count the number of analysts*/

proc sql;
    create table analys1 as
    select distinct ticker, CUSIP, OFTIC, count(ANALYS) as n_analys, mergedate
        from analys
        group by ticker, mergedate;
quit;


/* merge with granger combined data*/

proc sql;
create table granger_merged3
  as select a.*, b.ibtic
  from granger_merged2 a left join
      (select distinct gvkey, ibtic from comp.security
       where not missing(gvkey) and not missing(ibtic) and iid='01') b
  on a.gvkey=b.gvkey
  group by a.gvkey, date
  order by a.gvkey, date;
quit;


/*CRSP-IBES link table*/
%include "/home/ou/lzhangg/macros/iclink.sas";
%ICLINK (IBESID=IBES.ID,CRSPID=CRSP.STOCKNAMES,OUTSET=ICLINK);
 
 /*which firms have permnos, but have no matching IBES ticker*/
data noticker; set granger_merged3;
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
  create table granger_merged4 as
  select a.*, b.n_analys
  from granger_merged3 as a left join analys1 as b
  on a.ibtic=b.ticker and a.mergedate=b.mergedate;
quit;


data granger_merged4;set granger_merged4;
analycov=log(1+n_analys);
drop n_analys ibtic;
run;

proc sort data=granger_merged4 nodupkey;
by permno date;

data granger_merged4; set granger_merged4;
if missing(analycov) then analycov=0;
run;

proc print data=granger_merged4 (obs=200);
run;

endrsubmit;


/*Obtain return and abnormal return */

/* obtain return data from crsp */

rsubmit;

data return;
    set crspa.msf;
    if 2017 < year(date) < 2022;
	keep ret cusip date permno;
run;

/* calculate abnormal return */

%include "/home/ou/lzhangg/macros/Event_study.sas";
%ABRET (inset=return, outset=results, datevar=date, retvar=ret, freq=m, window=6, step=1, min=2, model=FF);

proc sort data=results;
by permno date;
run;


/*aggregate to quarterly return */

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

proc summary data=return;
by permno;
class date;
var RET;
format date YYQ6.;
output out= return (drop= _type_ _freq_) mean= ;
run;

data return; set return;
mergedate=qtr(date)||year(date);
run;

data return;set return;
if missing(date) then delete;
run;

proc sql;
  create table ret1 as
  select a.*, b.RET
  from ret as a left join return as b
  on a.permno=b.permno and a.mergedate=b.mergedate;
quit;

proc print data=ret1 (obs=100);
run;

endrsubmit;


/* get trading volume turnover from crsp*/


/* get monthly trading data*/
rsubmit;

data travol;
    set crspa.msf;
    if 2017 < year(date) < 2022;
	keep cusip date permno vol shrout;
run;


/*aggregate into quarterly data*/

proc summary data=travol;
by permno;
class date;
var vol shrout;
format date YYQ6.;
output out= travol (drop= _type_ _freq_) mean= ;
run;

data travol;set travol;
if date=. then delete;
run;


/* vol is recorded in 100s, and shares outstanding is recorded in 1000s*/

data travol;set travol;
turnover=vol/shrout/10;
if missing(turnover) then delete;
run;

data travol; set travol;
mergedate=qtr(date)||year(date);
run;

proc print data=travol (obs=100);
run;

endrsubmit;


/* merge with option data

proc sql;
  create table wsb_com2 as
  select a.*, b.abnormal_ret, b.RET
  from wsb_com1 as a left join ret as b
  on a.permno=b.permno and a.mergedate=b.mergedate;
quit;

proc print data=wsb_com2(obs=500);
run;

endrsubmit;*/



/*get institutional ownership variable*/

rsubmit;

libname tfn '/wrds/tfn/sasdata/s34';

* Items that can be changed;
%let tfn_ds= tfn.s34;              * The TFN dataset to be used ;
%let ikey= mgrno;                  * Investment company ID-- S34 set uses MGRNO, S12 uses FUNDNO;

%let year1 =  2011;                * First year (used to calculate date1 below) ;
%let year2 =  2022;                * Last year (used to calculate date2 below);

%let date1 = "01jan&year1"d ;      * Start of date range, Jan1 of year1;
%let date2 = "31dec&year2"d ;      * End of date range, Dec31 of year2;

* Step 1-- Pullout data, using proc sort step;
* And sort into the right order to sum shares by rdate within a cusip group; 
proc sort data=&tfn_ds 
     (keep= rdate cusip ticker shrout1 shrout2 prc shares &ikey)
     out=temp1; 
  where  (&date1 <= rdate <= &date2) ;
  by cusip rdate;
run;

* Last Step-- Sum up shares for each CUSIP, compute summary stats and create (output) results; 
*  The sum of shares is computed until the last case for the RQDATE, and then a single; 
*  observation for each RQDATE is put into the final data set;

data temp2;
  set temp1; 
  by cusip  rdate;
  if first.rdate then do;
    shares_held=0;
    n_held=0;
  end;

  if shares gt 0 then do;
    n_held + 1;
    shares_held + shares;
  end; 

  if last.rdate then do;
    total_shares_out= shrout1 * 1000000; *shrout1 is in millions; 
    if shrout2 gt 0 then total_shares_out= shrout2 * 1000; *shrout2 is in thousands; 
    if total_shares_out gt 0 then held_pct= shares_held / total_shares_out;
    if prc > 0 then do;
      total_market_value = prc * total_shares_out;
      held_value = prc * shares_held;
    end;
    output;
  end;
 keep cusip ticker rdate shares_held n_held total_shares_out total_market_value held_value held_pct;
run;

data aud_0_6; set temp2;
run;


*to obtain the ncusip (historical cusip) since TFN provides only historical cusips while compustat uses current cusip (cusip header);

libname crsp '/wrds/crsp/sasdata/a_stock ';
data STOCKNAMES; set crsp.STOCKNAMES; run;


proc sql;
       create table aud_0_6_1
       as select a.*, b.PERMNO, b.ncusip, b.CUSIP as c_cusip
       from aud_0_6 a left join STOCKNAMES b
       on not missing(a.cusip) and a.cusip = b.ncusip and a.rdate >= b.NAMEDT and a.rdate <= b.NAMEENDDT;
quit; 

proc sort data=aud_0_6_1 out = aud_0_6_2 nodupkey;
by cusip rdate;
run;


*to obtain institutional ownership at the beginning of year t;

data aud_1_0; set wsb_combined2;
Y_Beg = intnx('month',datadate, -11,'beginning'); format Y_Beg YYMMDD10.;
Y_End = intnx('day',datadate, 0,'end'); format Y_End YYMMDD10.;
cusip8 = substr(cusip, 1, 8);
run;

proc sort data=aud_1_0;
by cusip8 datadate;
run;

proc sql;
       create table aud_1_1
       as select a.*, b.rdate, b.held_pct, b.ncusip
       from aud_1_0 a left join aud_0_6_2 b
       on a.Tic = b.Ticker and a.cusip8 = b.c_cusip and a.Y_Beg >= b.rdate and a.Y_Beg -  365 <= b.rdate ;
quit; 

proc sort data=aud_1_1 nodupkey out=aud_1_2;
WHERE not missing(held_pct);
by cusip8 DATADATE rdate;
run;

data aud_1_3;set aud_1_2;
by cusip8 DATADATE rdate;
INSTIT_PCT = held_pct;
if last.datadate;
run;

*to add;
proc sql;
       create table wsb_combined3
       as select a.*, b.INSTIT_PCT
       from wsb_combined2 a left join aud_1_3 b
       on not missing(a.cusip) and a.cusip = b.cusip and a.datadate = b.datadate;
quit; 

proc sort data=wsb_combined3 nodupkey;
by gvkey Year;
run;

data wsb_combined3; set wsb_combined3;
if INSTIT_PCT> 1 then INSTIT_PCT=1;
if INSTIT_PCT=. then INSTIT_PCT=0;
run;

proc print data=wsb_combined3 (obs=100);
run;

endrsubmit;



/* construct additional control variables */
rsubmit;

options dlcreatedir;  
libname mydata "~/mydatasets";

data controls;
    set compd.fundq;
	where indfmt="INDL" and datafmt="STD" and consol="C";
    if 2017 < fyearq < 2022 ;
	if 6000 le sich le 6799 then delete;
	keep gvkey tic cusip fyearq datacqtr datafqtr apdedateq fyr ibq oancfy atq prccq cshoq ceqq dlttq dlcq;
run;

data quarterly; set controls;
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

data quarterly2; set controls;
if not missing(apdedateq);
run;

data controls1;set quarterly2 quarterly1;
run;

proc sort data=controls1;
by gvkey datacqtr;
run;

endrsubmit;



rsubmit;

/* obtain t-1 assets */
%let byvars=gvkey;
data controls1;set controls1;
by &byvars datacqtr;
lag1_atq=lag(atq);
if first.%scan(&byvars,-1) then lag1_atq=.;
run;


/* get accruals,Earn,MTB,Leverage and Loss variables */
/* Accruals: earnings before extraordinary items minus operating cash flows, scaled by t-1 total assets*/
data controls2; set controls1;
if missing(lag1_atq) then delete;
Accruals=(ibq-oancfy)/lag1_atq;
Earn=ibq/lag1_atq;
MTB= (prccq*cshoq)/ceqq;
Leverage=(dlcq+dlttq)/atq;
CFO=oancfy/lag1_atq;
if ibq<0 then Loss=1;
else Loss=0;
if missing(Accruals) then delete;
if missing(Earn) then delete;
if missing(Leverage) then delete;
if missing(CFO) then delete;
run;


/*get Earn_t+1 and CFO_t+1 variables*/
proc sort data=controls2;
by gvkey descending datacqtr;
run;


data controls3;set controls2;
by gvkey descending datacqtr;
lead_Earn = lag(Earn);
lead1_CFO = lag(CFO);
if first.gvkey then lead_Earn=.;
if first.gvkey then lead1_CFO=.;
if missing (lead_Earn) then delete;
if missing (lead1_CFO) then delete;
run;

data controls3;set controls3;
by gvkey descending datacqtr;
lead2_CFO = lag(lead1_CFO);
if first.gvkey then lead2_CFO=.;
if missing (lead2_CFO) then delete;
run;

data controls3;set controls3;
by gvkey descending datacqtr;
lead3_CFO = lag(lead2_CFO);
if first.gvkey then lead3_CFO=.;
if missing (lead3_CFO) then delete;
run;


proc print data=controls3 (obs=100);
run;

endrsubmit;


/* construct BEAT variable, which is defined as an indicator variable equaling 1*/
/* if earnings scaled by total assets in quarter t is greater than t-1 by 0.005 or less, and zero otherwise */
rsubmit;

data controls4; set controls3;
CFO_t3=lead1_CFO+lead2_CFO+lead3_CFO;
Earnings=ibq/atq;
drop lead2_CFO lead3_CFO;
run;

proc sort data=controls4;
by gvkey datacqtr;
run;

%let byvars=gvkey;
data controls4;set controls4;
by &byvars datacqtr;
lag1_Earnings=lag(Earnings);
if first.%scan(&byvars,-1) then lag1_Earnings=.;
if missing(lag1_Earnings) then delete;
if (Earnings-lag1_Earnings) le 0.005 then Beat=1;
else Beat=0;
drop Earnings lag1_Earnings;
run;

proc print data=controls4 (obs=100);
run;

endrsubmit;

