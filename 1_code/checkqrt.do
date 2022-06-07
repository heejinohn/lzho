* Calls and puts

** Read data and set panel
use ~/Downloads/cpvol.dta, replace
replace date = dofc(date)
xtset secid date, daily

** Calculcate call - put open interest
bysort secid : gen d_gap = int_gap - int_gap[_n-1]

** Calculate cross-sectional monthly average of daily call volumes
gen dm = mofd(date)
format dm %tm
collapse volume_C int_gap, by(dm)
tsset dm, monthly

** Test for structural breaks
qui reg int_gap volume_C

estat sbsingle

foreach x in 2017m12 2018m1 2020m2 2020m4 2020m5{
    estat sbknown, break(tm(`x'))
}

forval i = 8/12 {
    estat sbknown, break(tm(2017m`i'))
}


* Total

** Read data and set panel
use ~/Downloads/tvol.dta, replace
replace date = dofc(date)
xtset secid date, daily

** Calculate cross-sectional monthly average of daily call volumes
gen dm = mofd(date)
format dm %tm
collapse tvol tinterest, by(dm)
tsset dm, monthly

** Test for structural breaks
qui reg tinterest tvol

estat sbsingle

foreach x in 2017m12 2018m1 2020m2 2020m4 2020m5{
    estat sbknown, break(tm(`x'))
}

forval i = 8/12 {
    estat sbknown, break(tm(2017m`i'))
}
