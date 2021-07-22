use ~/Downloads/cpvol.dta, replace
replace date = dofc(date)
xtset secid date
format date %td:
bysort secid : gen d_gap = int_gap - int_gap[_n-1]
preserve
drop if d_gap == 0
restore
