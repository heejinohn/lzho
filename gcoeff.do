//// Get data
use ~/Downloads/merge.dta, clear

//// Generate ticker ID
egen ticid = group(tic), label(tic)

//// Check duplicates
drop if inlist(index, 154846, 1670141, 2743357, 3683241)
drop index
sort tic date
gen yq = qofd(date)
format yq %tq
egen tic_q = concat(tic yq), punc(_)
save ~/Downloads/merge_nodup.dta, replace
// duplicates report ticid date, sepby(ticid)
// isid ticid date

//// Run granger by ticker
use ~/Downloads/merge_nodup.dta, clear
xtset ticid date
matrix G = J(1,3,.)
matrix colnames G = "chi2" "df" "p"
qui levelsof tic_q
foreach val in `r(levels)' {
    capture noisily var activity score posts if tic_q == `"`val'"'
    if _rc == 0 {
        qui vargranger
        matrix g = r(gstats)
        if rowsof(g) == 1 {
            local eq "ALL"
        }
        else {
            local eq: roweq g
        }
        foreach w of local eq {
            local new "`new' `val'_`w'"
        }
        matrix roweq g = `new'
        matrix  G = (G \ g)
        local new
    }
}
drop _all
svmat G, names(col)
gen roweq = ""
gen tic = ""
gen lead = ""
gen lags = ""
local eq: roweq(G)
local lags: rownames(G)
forval i = 1/`: rowsof(G)' {
    replace roweq = "`: word `i' of `eq''" in `i'
    replace lags = "`: word `i' of `lags''" in `i'
}
