/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 000_cr_define_covariates_simple_rates.do
//
// This program takes inputs generated from the study 
//   definitions and converts dates into usable format
//
// Authors: Robin (based on Alex & John)
// Date: 6 Oct 2021
// Updated: 22 Oct 2021
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

clear
do `c(pwd)'/analysis/global.do
global group `1'

if "$group" == "covid_2020"  | "$group" == "matched_2020" { 
	local start_date td(01/02/2020)
	local end_date td(30/11/2020)
}
else if "$group" == "covid_2021"  | "$group" == "matched_2021" { 
	local start_date td(01/02/2021)
	local end_date td(30/11/2021)
}
else {
	local start_date  td(01/02/2019)
	local end_date td(30/11/2019)
}

import delimited $outdir/input_${group}_with_duration.csv


* Indexdate
gen indexdate = date(patient_index_date, "YMD")
format indexdate %td
drop patient_index_date
drop if indexdate == .

save $outdir/cohort_rates_${group}_TEST, replace
