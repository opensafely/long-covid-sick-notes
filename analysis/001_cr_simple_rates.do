////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 001_cr_simple_rates.do
//
// This program generates absolute survival rates, 
//   examining each individiual population separately 
//
// Authors: Robin (based on Alex & John)
// Date: 8 Oct 2021
// Updated: 8 Oct 2021
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

do `c(pwd)'/analysis/global.do
global group `1'

use $outdir/cohort_rates_$group, clear 

if "$group" == "covid_2020" | "$group" == "pneumonia_2019"  { 
	global stratifiers "agegroup male ethnicity long_hosp_stay"
}
else {
	global stratifiers "agegroup male ethnicity"
}

tempname measures
																	 
	postfile `measures' str16(group) str25(outcome) str12(time) ///
	str20(variable) category personTime numEvents rate lc uc ///
	using $tabfigdir/rates_summary_$group, replace
	
	preserve
	cap drop time
	
	local out sick_note_1_date
	local end_date sick_note_1_date_end_date
	
	stset `end_date', id(patient_id) failure(`out') enter(indexdate) origin(indexdate)
		
	* Overall rate 
	stptime  
	* Save measure
	local events .
	if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
	post `measures' ("$group") ("`out'") ("Full period") ("Overall") (0) (`r(ptime)') 	///
						(`events') (`r(rate)') 								///
						(`r(lb)') (`r(ub)')
		
	* Stratified - additionally include long_hosp_stay for hosp patients
		
	foreach c of global stratifiers {
		
		qui levelsof `c' , local(cats) 
		di `cats'
		foreach l of local cats {
			noi di "$group: Calculate rate for variable `c' and level `l'" 
			qui  count if `c' ==`l'
			if `r(N)' > 0 {
			stptime if `c'==`l'
			* Save measures
			local events .
			if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
			post `measures' ("$group") ("`out'") ("Full period") ("`c'") (`l') (`r(ptime)')	///
							(`events') (`r(rate)') 							///
							(`r(lb)') (`r(ub)')
			}

		else {
			post `measures' ("$group") ("`out'") ("Full period") ("`c'") (`l') (.) 	///
						(.) (.) 								///
						(.) (.) 
			}
					
		}
	}
	
* Stsplit data into 30 day periods
	stsplit time, at(30(30)120)
		
	* Overall rate 
	forvalues t = 0(30)120 {
	qui  count if time ==`t'
	if `r(N)' > 0 {
		stptime if time ==`t'
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("$group") ("`out'") ("`t' days") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
			
		
	}
	else {
		post `measures' ("$group") ("`out'") ("`t' days") ("Overall") (0) (.) 	///
							(.) (.) 								///
							(.) (.) 
		}
	}
 
  restore  

postclose `measures'

* Change postfiles to csv
use $tabfigdir/rates_summary_$group, replace

* Change from per person-day to per 100 person-months
gen rate_ppm = 100*(rate * 365.25 / 12)
gen lc_ppm = 100*(lc * 365.25 /12)
gen uc_ppm = 100*(uc * 365.25 /12)

export delimited using $tabfigdir/rates_summary_$group.csv, replace
