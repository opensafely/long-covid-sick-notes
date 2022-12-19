////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 202_cox_models_stsplit_2021_pneumo.do
//
// This program runs Cox models to perform survival analysis.
//
// Authors: Andrea (based on Robin, Alex & John)
// Date: 02 Dec 2022
// Updated: 
// Input files: 
// Output files: 
//
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

clear
do `c(pwd)'/analysis/global.do

cap log close
log using $outdir/cox_models_split_2021_pneumo.txt, replace t

tempname measures
	postfile `measures' ///
 		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) str10(month) ///
		hr lc uc  ///
		ptime_covid events_covid rate_covid /// 
		ptime_comparator events_comparator rate_comparator ///
		using $tabfigdir/cox_model_split_summary_2021_pneumo, replace
		
use $outdir/combined_covid_2021_pneumonia.dta, replace
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
* Age, sex, region, imd WITHOUT ETHNICITY
global demo_noeth i.case##i.month i.male age1 age2 age3 i.region_9 i.imd
* Demographics + clinical WITH ETHNICITY
global demo_noeth_clinical i.case##i.month i.male age1 age2 age3 i.region_9 i.imd /// 
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
		
        stsplit month, at(30, 90, 150)

		tab month sick_note

		foreach adjust in crude age_sex demo_eth demo_eth_clinical demo_noeth demo_noeth_clinical {
            
            foreach mon in 0 30 90 150 {
				
			    stcox $`adjust', vce(robust) 

                lincom 1.case + 1.case#`mon'.month, hr

			    local hr = r(estimate)
                local lc = r(lb)
                local uc = r(ub)

				stptime if case == 1 & month == `mon'
				local rate_covid = `r(rate)'
				local ptime_covid = `r(ptime)'
				local events_covid .
				if `r(failures)' == 0 | `r(failures)' > 5 local events_covid `r(failures)'
			
				stptime if case == 0 & month == `mon'
				local rate_comparator = `r(rate)'
				local ptime_comparator = `r(ptime)'
				local events_comparator .
				if `r(failures)' == 0 | `r(failures)' > 5 local events_comparator `r(failures)'

				post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'") ("`mon'") ///
					(`hr') (`lc') (`uc') ///
					(`ptime_covid') (`events_covid') (`rate_covid') ///
					(`ptime_comparator') (`events_comparator')  (`rate_comparator') 

			}
		}
			
	}
	restore	

postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_split_summary_2021_pneumo, replace

export delimited using $tabfigdir/cox_model_split_summary_2021_pneumo.csv, replace
log close
