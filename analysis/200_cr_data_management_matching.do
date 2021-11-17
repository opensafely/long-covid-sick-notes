////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 200_cr_data_management_matching.do
//
// This program combines the main cohort data with  
//   comparator population data 
//
// Authors: Robin (based on Alex & John)
// Date: 15 Oct 2021
// Updated: 15 Oct 2021
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

clear
do `c(pwd)'/analysis/global.do

********************************************************************************
* Append covid/pneumonia cohorts 
********************************************************************************

ls $outdir/

cap log close
log using $outdir/append_cohorts.txt, replace t

* Gen flag for covid patients  (case = 1)
use $outdir/cohort_rates_covid_2020, replace
gen case = 1 
append using $outdir/cohort_rates_pneumonia_2019, force
replace case = 0 if case ==.

* count patients from pneumonia group who are among covid group
bysort patient_id: gen flag = _n
safecount if flag == 2

* drop if not hopitalised 
drop if hosp_expo_date == .

noi di "number of patients in both cohorts is `r(N)'"

drop flag 
save $outdir/combined_covid_pneumonia.dta, replace

********************************************************************************
* Append covid/gen pop. cohorts 
********************************************************************************

foreach year in 2019 2020 {
	* Gen flag for covid patients  (case = 1)
	use $outdir/cohort_rates_covid_2020, replace
	gen case = 1 
	append using $outdir/cohort_rates_general_`year', force
	replace case = 0 if case ==.

	* count patients from general group who are among covid group
	bysort patient_id: gen flag = _n
	safecount if flag == 2

	noi di "number of patients in both cohorts is `r(N)'"

	drop flag 
	save $outdir/combined_covid_general_`year'.dta, replace
}

log close
