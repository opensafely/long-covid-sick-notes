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

di "STARTING COUNT FROM IMPORT:"
noi safecount

* Indexdate
gen indexdate = date(patient_index_date, "YMD")
format indexdate %td
drop patient_index_date
drop if indexdate == .

* remove any patient with index date after end date
drop if indexdate > `end_date'

* Drop if missing region/IMD
drop if imd == .
drop if imd < 1
drop if imd > 5
drop if region == ""


if "$group" == "covid_2020" | "$group" == "covid_2021" { 
	gen hosp_expo_date = date(hospital_covid, "YMD")
	format hosp_expo_date %td
}

if "$group" == "pneumonia_2019"  { 
	gen hosp_expo_date = date(pneumonia_admission_date, "YMD")
	format hosp_expo_date %td
}


save $outdir/cohort_rates_${group}_TEST, replace
