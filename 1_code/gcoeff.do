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
tempfile mat
save `mat', emptyok
use ~/Downloads/merge_nodup.dta, clear
keep in f/818
qui levelsof tic_q
foreach val in `r(levels)' {
    use ~/Downloads/merge_nodup.dta, clear
    xtset ticid date
    di `"`val'"'
    capture noisily qui var activity score posts if tic_q == `"`val'"'
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
        drop _all
        svmat g, names(col)
        gen roweq = ""
        gen lags = ""
        local eq: roweq(g)
        local lags: rownames(g)
        forval i = 1/`: rowsof(g)' {
            replace roweq = "`: word `i' of `eq''" in `i'
            replace lags = "`: word `i' of `lags''" in `i'
        }
        append using `mat'
        save `"`mat'"', replace
        local new
    }
}
save test, replace
use test
drop if missing(chi2)
keep chi2-lags
gen ticker = substr(roweq,1,strpos(roweq,"_")-1)
gen lead = substr(roweq,strrpos(roweq,"_"),.)
gen yearq = real(substr(roweq,strpos(roweq,"_")+1),3)
format yearq %tq
save, replace
