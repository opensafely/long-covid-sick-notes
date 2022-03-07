////////////////////////////////////////////////////////////
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

if "$group" == "covid_2020"  | "$group" == "general_2020" { 
	local start_date  td(01/02/2020)
	local last_year   td(01/02/2019)
	local four_years_ago td(01/02/2015)	 
	local fifteen_months_ago td(01/09/2019)
	local end_date td(30/11/2020)
}
else if "$group" == "covid_2021"  | "$group" == "general_2021" { 
	local start_date  td(01/02/2021)
	local last_year   td(01/02/2020)
	local four_years_ago td(01/02/2016)	 
	local fifteen_months_ago td(01/09/2020)
	local end_date td(30/11/2021)
}
else {
	local start_date  td(01/02/2019)
	local last_year   td(01/02/2018)	
	local four_years_ago td(01/02/2014)	 
	local fifteen_months_ago td(01/09/2018)
	local end_date td(30/11/2019)
}

** Commented out matching code
* if "$group" == "matched_matches_2019" | "$group" == "matched_matches_2020" {
*	import delimited $outdir/$group.csv
*	drop if case == 1 
*	global group "gen_population"
*}
*else {
*	import delimited $outdir/input_${group}_with_duration.csv
*}

import delimited $outdir/input_${group}_with_duration.csv

di "STARTING COUNT FROM IMPORT:"
noi safecount

* Indexdate
if "$group" == "general_2020" {
	gen indexdate = td(01/02/2020)
}
else if "$group" == "general_2021" {
	gen indexdate = td(01/02/2021)
}
else if "$group" == "general_2019" {
	gen indexdate = td(01/02/2019)
}
else {
	gen indexdate = date(patient_index_date, "YMD")
	format indexdate %td
	drop patient_index_date
}

drop if indexdate ==.

* remove any patient discharged after end date
drop if indexdate > `end_date'

if "$group" == "covid_2020" | "$group" == "covid_2021" { 
	gen hosp_expo_date = date(hospital_covid, "YMD")
}
if "$group" == "pneumonia_2019"  { 
	gen hosp_expo_date = date(pneumonia_admission_date, "YMD")
}

if "$group" == "covid_2020" | "$group" == "covid_2021" | "$group" == "pneumonia_2019"  { 
	format hosp_expo_date %td
	* Length of stay
	gen length_of_stay = indexdate - hosp_expo_date + 1
	label var length_of_stay "Length of stay in hospital (days)"
	hist length , name(length_of_stay_$group, replace) graphregion(color(white)) col(navy%50) ylab(,angle(h)) lcol(navy%20)
	graph export $tabfigdir/length_of_stay_$group.svg , as(svg) replace

	* Create flag for patients staying in hospital longer than the median length
	summ length, detail
	gen long_hosp_stay = cond(length_of_stay >= `r(p50)' , 1, 0)
}

******************************
*  Convert strings to dates  *
******************************
foreach var of varlist sgss_positive					///
					   primary_care_covid  		    	///
					   hospital_covid					///
					   died_date_ons					///
					   deregistered						///
					   sick_note_1_date 				///
					   covid_diagnosis_date 	    	{

	capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
		else {
			if  ("`var'" == "primary_care_covid") |  ///
				("`var'" == "hospital_covid") 	  |  ///
				("`var'" == "deregistered") 	  {
					rename `var' `var'_dstr
					gen `var'_date = date(`var'_dstr, "YMD") 
					order `var'_date, after(`var'_dstr)
					drop `var'_dstr
					format `var'_date %td
			}
			else {
				rename `var' `var'_dstr
				gen `var' = date(`var'_dstr, "YMD") 
				order `var', after(`var'_dstr)
				drop `var'_dstr
				format `var' %td
			}
		}
}

* drop if died before discharge date
drop if died_date_ons <= indexdate

* Note: There may be deaths recorded after end of our study 
* Set these to missing
replace died_date_ons = . if died_date_ons>`end_date'

**********************
*  Recode variables  *
**********************

/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
label define sexLab 1 "male" 0 "female"
label values male sexLab
label var male "sex = 0 F, 1 M"

* Ethnicity (5 category)
replace ethnicity = 6 if ethnicity==.
label define ethnicity_lab 	1 "White"  						///
							2 "Mixed" 						///
							3 "Asian or Asian British"		///
							4 "Black"  						///
							5 "Other"						///
							6 "Unknown"
label values ethnicity ethnicity_lab


/*  Geographical location  */

* Region
rename region region_string
assert inlist(region_string, 								///
					"East Midlands", 						///
					"East",  								///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and The Humber") 
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and The Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East"   							///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and The Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
	
**************************
*  Categorise variables  *
**************************
rename age_group temp
encode temp, gen(age_group)
drop temp

* Check there are no missing ages
assert age<.

* Create restricted cubic splines for age
cap drop age1
mkspline age = age, cubic nknots(4)

***************************
*  Grouped comorbidities  *
***************************

**************
*  Outcomes  *
**************	

* Post outcome distribution 
tempname outcomeDist
																	 
	postfile `outcomeDist' str20(outcome) str12(type) numEvents percent using $tabfigdir/outcome_distribution_$group.dta, replace

* The default deregistration date is 9999-12-31, so:
replace deregistered = . if deregistered > `end_date'

gen sick_note = 1 if sick_note_1_date != .
recode sick_note . = 0

foreach out in sick_note {
	if "$group" == "covid_2020" | "$group" == "covid_2021" {
		gen min_end_date = min(`out'_1_date, died_date_ons, deregistered_date) // `out'_ons already captured in the study definition binary outcome
	}
	else {
		gen min_end_date = min(`out'_1_date, died_date_ons, deregistered_date, covid_diagnosis_date)
	}

	* Define outcome using all data
	replace `out' = 0 if min_end_date > `end_date'
	gen 	`out'_end_date = `end_date' // relevant end date
	replace `out'_end_date = min_end_date if min_end_date!=.	 // not missing
	replace `out'_end_date = `out'_end_date + 1 
	format %td `out'_end_date 

	drop min_end_date	

}

postclose `outcomeDist'
										
order patient_id indexdate

save $outdir/cohort_rates_$group, replace
