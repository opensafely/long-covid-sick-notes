////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 201_cox_models.do
//
// This program runs Cox models to perform survival analysis.
//
// Authors: Robin (based on Alex & John)
// Date: 15 Oct 2021
// Updated: 18 Oct 2021
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

clear
do `c(pwd)'/analysis/global.do

cap log close
log using $outdir/cox_models.txt, replace t

tempname measures
	postfile `measures' ///
		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) ptime_covid num_events_covid rate_covid /// 
		ptime_comparator num_events_comparator rate_comparator hr lc uc ///
		using $tabfigdir/cox_model_summary, replace
		
foreach an in pneumonia general_2019 general_2020 {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

* Crude
global crude i.case
* Age and sex adjusted
global age_sex i.case i.male age1 age2 age3
* Age, sex, ethnicity, region, imd
global demographics i.case i.male age1 age2 age3 region_9 imd
* Demographics + clinical
global demo_clinical i.case i.male age1 age2 age3 region_9 imd /// 
					 i.emergency_care i.obese smoking_status i.hypertension ///
					 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
					 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_disease ///
					 i.other_neuro i.organ_transplant i.dysplenia i.hiv i.permanent_immunodef ///
					 i.by_sys i.bp_dias i.ra_sle_psoriasis

foreach v in sick_note {
	
	noi di "Starting analysis for `v' Outcome ..." 
		
	preserve
	
		local end_date `v'_end_date
		local out `v'
				
		noi di "$group: stset in `a'" 
		
		stset `end_date', id(new_patient_id) failure(`out') enter(indexdate) origin(indexdate)
		
		foreach adjust in crude age_sex demographics demo_clinical {
			stcox $`adjust', vce(robust)

			matrix b = r(table)
			local hr = b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]

			stptime if case == 1
			local rate_covid = `r(rate)'
			local ptime_covid = `r(ptime)'
			local events_covid .
			if `r(failures)' == 0 | `r(failures)' > 5 local events_covid `r(failures)'
			
			stptime if case == 0
			local rate_comparator = `r(rate)'
			local ptime_comparator = `r(ptime)'
			local events_comparator .
			if `r(failures)' == 0 | `r(failures)' > 5 local events_comparator `r(failures)'

			post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'")  ///
							(`ptime_covid') (`events_covid') (`rate_covid') (`ptime_comparator') (`events_comparator')  (`rate_comparator')  ///
							(`hr') (`lc') (`uc')
			
			}
	
	restore			

}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary, replace

export delimited using $tabfigdir/cox_model_summary.csv, replace

log close
