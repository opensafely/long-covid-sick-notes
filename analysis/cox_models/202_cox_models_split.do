////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 202_cox_models_split.do
//
// This program runs piecewise Cox models.
//
// Authors: Andrea (based on Robin, Alex & John)
// Date: 
// Updated: 01 Jun 2023
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

clear
do `c(pwd)'/analysis/global.do
global group `1'

cap log close
log using $outdir/cox_models_split_$group.txt, replace t

tempname measures
	postfile `measures' ///
 		str20(comparator) str10(adjustment) str10(month) hr lc uc  ///
		ptime_covid events_covid ptime_comparator events_comparator ///
		using $tabfigdir/cox_model_split_summary_$group, replace
		
use $outdir/combined_covid_$group.dta, replace
drop patient_id
gen new_patient_id = _n

## Encode smoking status and ethnicity
encode smoking_status, gen(smoking_category)

* Crude
global crude i.case##i.month
* Age and sex adjusted
global age_sex i.case##i.month i.male age1 age2 age3
* Age, sex, region, imd WITH ETHNICITY
global demo_eth i.case##i.month i.male age1 age2 age3 i.ethnicity i.region_9 i.imd
* Demographics + clinical WITH ETHNICITY
global demo_eth_clinical i.case##i.month i.male age1 age2 age3 i.ethnicity i.region_9 i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis


stset sick_note_end_date, id(new_patient_id) failure(sick_note) enter(indexdate) origin(indexdate)

stsplit month, at(30, 90, 150)

tab month sick_note

foreach adjust in crude age_sex demo_eth demo_eth_clinical  {
            
	stcox $`adjust', vce(robust) 
		
		foreach mon in 0 30 90 150 {

		lincom 1.case + 1.case#`mon'.month, hr

		local hr = r(estimate)
		local lc = r(lb)
		local uc = r(ub)

		stptime if case == 1 & month == `mon'
		local ptime_covid = `r(ptime)'
		local events_covid .
		local events_covid round(`r(failures)'/ 7 ) * 7
			
		stptime if case == 0 & month == `mon'
		local ptime_comparator = `r(ptime)'
		local events_comparator .
		local events_comparator round(`r(failures)'/ 7 ) * 7

		post `measures'  ("$group")  ("`adjust'") ("`mon'") (`hr') (`lc') (`uc') ///
			(`ptime_covid') (`events_covid') (`ptime_comparator') (`events_comparator')  

	}
}

postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_split_summary_$group, replace

export delimited using $tabfigdir/cox_model_split_summary_$group, replace
log close
