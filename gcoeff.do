//// Get data
use ~/Downloads/merge.dta, clear

//// Generate ticker ID
egen ticid = group(tic), label(tic)

//// Check duplicates
drop if inlist(index, 154846, 1670141, 2743357, 3683241)
duplicates report ticid date, sepby(ticid)
// isid ticid date

//// Define panel
xtset ticid date

//// Run granger by ticker
qui levelsof ticid
forval lev = 1/1000 {
    qui var activity score posts if ticid == `lev'
    di "Ticker = `: label (ticid) `lev''"
    vargranger
}
