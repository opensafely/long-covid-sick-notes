////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 100_cr_simple_rates.do
//
// This program generates absolute survival rates, 
//   examining each individiual population separately 
//
// Authors: Robin (based on Alex & John)
// Date: 8 Oct 2021
// Updated: 01 Jun 2023
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

do `c(pwd)'/analysis/global.do
global group `1'

use $outdir/cohort_rates_$group, clear 

global stratifiers "age_group male ethnicity region_9 imd"

* Drop if not hospitalised
drop if hosp_expo_date == .

* Redefine indexdate to admission date
drop indexdate
gen indexdate = hosp_expo_date

drop if sick_note_end_date < indexdate

tempname measures
																	 
	postfile `measures' str16(group) str12(time) ///
	str20(variable) category personTime numEvents ///
	using $tabfigdir/rates_summary_hosp_$group, replace
	
	preserve
	cap drop time
	
	stset sick_note_end_date, id(patient_id) failure(sick_note) enter(indexdate) origin(indexdate)
		
	* Overall rate 
	stptime  
	
	* Save measure
	local events .
	local events round(`r(failures)'/ 7 ) * 7
	post `measures' ("$group") ("Full period") ("Overall") (0) (`r(ptime)') (`events') 
		
	* Stratified
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
			local events round(`r(failures)'/ 7 ) * 7
			post `measures' ("$group") ("Full period") ("`c'") (`l') (`r(ptime)') (`events') 
			}

		else {
			post `measures' ("$group") ("Full period") ("`c'") (`l') (.) 	(.) 
			}
					
		}
	}
	
* Stsplit data into 30 day periods
	stsplit time, at(30, 90, 150)
		
	* Overall rate 
	foreach t in 0 30 90 150 {
	qui  count if time ==`t'
	if `r(N)' > 0 {
		stptime if time ==`t'
		* Save measure
		local events .
		local events round(`r(failures)'/ 7 ) * 7
		post `measures' ("$group") ("`t' days") ("Overall") (0) (`r(ptime)') (`events') 
	}
	else {
		post `measures' ("$group") ("`t' days") ("Overall") (0) (.) (.)
		}
	}
 
  restore  

postclose `measures'

* Change postfiles to csv
use $tabfigdir/rates_summary_hosp_$group, replace

* Change from per person-day to per 100 person-months
gen rate = numEvents / personTime 
gen rate_ppm = 100*(rate * 365.25 / 12)

export delimited using $tabfigdir/rates_summary_hosp_$group.csv, replace
