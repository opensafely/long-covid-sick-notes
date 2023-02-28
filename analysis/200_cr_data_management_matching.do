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
// Updated: 25 Jan 2023
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

foreach year in 2020 2021 {
	* Gen flag for covid patients  (case = 1)
	use $outdir/cohort_rates_covid_`year', replace
	gen case = 1 
	append using $outdir/cohort_rates_pneumonia_2019, force
	replace case = 0 if case ==.

	* count patients from pneumonia group who are among covid group
	bysort patient_id: gen flag = _n
	safecount if flag == 2

	* drop if not hospitalised 
	drop if hosp_expo_date == .

	* replace indexdate with admission date
	drop indexdate
	gen indexdate = hosp_expo_date
	
	* Drop if sick note between initial diagnosis and hospitalisation
	drop if sick_note_end_date <= indexdate

	noi di "number of patients in both cohorts is `r(N)'"

	drop flag 
	save $outdir/combined_covid_`year'_pneumonia.dta, replace
}
	
********************************************************************************
* Append covid/gen pop. cohorts 
********************************************************************************

foreach year in 2020 2021 {
	*** 2020 and 2021
	* Gen flag for covid patients  (case = 1)
	use $outdir/cohort_rates_covid_`year', replace
	gen case = 1 
	append using $outdir/cohort_rates_matched_`year', force
	replace case = 0 if case ==.

	* count patients from general group who are among covid group
	bysort patient_id: gen flag = _n
	safecount if flag == 2

	noi di "number of patients in both cohorts is `r(N)'"

	drop flag 
	save $outdir/combined_covid_general_`year'.dta, replace

	*** 2019
	* Gen flag for covid patients  (case = 1)
	use $outdir/cohort_rates_covid_`year', replace
	gen case = 1 
	append using $outdir/cohort_rates_matched_2019, force
	replace case = 0 if case ==.

	* count patients from general group who are among covid group
	bysort patient_id: gen flag = _n
	safecount if flag == 2

	noi di "number of patients in both cohorts is `r(N)'"

	drop flag 
	save $outdir/combined_covid_`year'_general_2019.dta, replace
}

log close
