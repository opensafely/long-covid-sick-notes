////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 204_cox_models_split_stratified_imd.do
//
// This program runs piecewise Cox models by IMD subgroup. 
//
// Authors: Andrea (based on Robin, Alex & John)
// Date: 02 Dec 2022
// Updated: 01 Jun 2023
// Input files: 
// Output files: 
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

set varabbrev off

clear
do `c(pwd)'/analysis/global.do
global group `1'

cap log close
log using $outdir/cox_models_split_${group}_imd.txt, replace t

tempname measures
	postfile `measures' ///
 		str20(var) str20(category) str20(comparator) str10(adjustment) str10(month) ///
		hr lc uc  ///
		ptime_covid events_covid /// 
		ptime_comparator events_comparator ///
		using $tabfigdir/cox_model_split_summary_${group}_imd, replace
		
use $outdir/combined_covid_${group}.dta, replace
drop patient_id
gen new_patient_id = _n

* Encode smoking status 
encode smoking_status, gen(smoking_category)

* Crude
global crude i.case##i.month

* Full adjustment excluding age
global full i.case##i.month age1 age2 age3 i.male i.ethnicity i.region_9  /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis

stset sick_note_end_date, id(new_patient_id) failure(sick_note) enter(indexdate) origin(indexdate)

stsplit month, at(30, 90, 150)

tab month sick_note

levelsof imd

        foreach level in `r(levels)' {  

		    foreach adjust in crude full {
            
			    foreach mon in 0 30 90 150 {
				
				stcox $`adjust' if imd  == `level', vce(robust) 

				lincom 1.case + 1.case#`mon'.month, hr

				local hr = r(estimate)
				local lc = r(lb)
				local uc = r(ub)

				stptime if case == 1 & month == `mon' & imd == `level'
				local ptime_covid = `r(ptime)'
				local events_covid .
				local events_covid round(`r(failures)'/ 7 ) * 7
			
				stptime if case == 0 & month == `mon' & imd == `level'
				local ptime_comparator = `r(ptime)'
				local events_comparator .
				local events_comparator round(`r(failures)'/ 7 ) * 7

				post `measures' ("imd") ("`level'") ("$group") ("`adjust'") ("`mon'") ///
					(`hr') (`lc') (`uc') ///
					(`ptime_covid') (`events_covid') (`ptime_comparator') (`events_comparator')

			    }
		    }
        }
postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_split_summary_${group}_imd, replace

export delimited using $tabfigdir/cox_model_split_summary_${group}_imd, replace
log close
