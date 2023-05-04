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
global var `1'

cap log close
log using $outdir/cox_models_stratified_$var.txt, replace t

tempname measures
	postfile `measures' ///
		str20(var) str20(category) str20(comparator) str20(outcome) str25(analysis) str10(adjustment) ///
		ptime_covid num_events_covid rate_covid /// 
		ptime_comparator num_events_comparator rate_comparator hr lc uc ///
		using $tabfigdir/cox_model_summary_$var, replace
		
foreach an in 2020_pneumonia 2021_pneumonia 2020_general_2019 2021_general_2019 general_2020 general_2021 {

use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

* Encode smoking status and ethnicity
encode smoking_status, gen(smoking_category)

* Crude
global crude i.case

global age_group i.case i.male i.ethnicity i.region_9 i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis

global male i.case age1 age2 age3 i.ethnicity i.region_9 i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis

global ethnicity i.case i.male age1 age2 age3 i.region_9 i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis
                         
global imd i.case i.male age1 age2 age3 i.ethnicity i.region_9 /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis
                         
global region_9 i.case i.male age1 age2 age3 i.ethnicity i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis


foreach v in sick_note {
	
	noi di "Starting analysis for `v' Outcome ..." 
		
	preserve
	
		local end_date `v'_end_date
		local out `v'
				
		noi di "$group: stset in `a'" 
	        
		stset `end_date', id(new_patient_id) failure(`out') enter(indexdate) origin(indexdate)

        levelsof $var

        foreach level in `r(levels)' {
		
		    foreach adjust in crude $var {

			    stcox $`adjust' if $var == `level', vce(robust)

			    matrix b = r(table)
			    local hr = b[1,2]
			    local lc = b[5,2] 
			    local uc = b[6,2]

			    stptime if case == 1 & $var == `level'
			    local rate_covid = `r(rate)'
			    local ptime_covid = `r(ptime)'
			    local events_covid .
			    local events_covid round(`r(failures)'/ 5 ) * 5
			
			    stptime if case == 0 & $var == `level'
			    local rate_comparator = `r(rate)'
			    local ptime_comparator = `r(ptime)'
			    local events_comparator .
			    local events_comparator round(`r(failures)'/ 5 ) * 5

			    post `measures' ("$var") ("`level'") ("`an'") ("`v'") ("`out'") ("`adjust'")  ///
							(`ptime_covid') (`events_covid') (`rate_covid') (`ptime_comparator') (`events_comparator') (`rate_comparator')  ///
							(`hr') (`lc') (`uc')
			
			}
        }
	restore			

}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary_$var, replace

export delimited using $tabfigdir/cox_model_summary_$var.csv, replace

log close
