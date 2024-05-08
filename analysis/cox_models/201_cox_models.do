////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//
// 201_cox_models.do
//
// This program runs Cox models to perform survival analysis.
//
// Authors: Robin (based on Alex & John) updated by Rose
// Date: 15 Oct 2021
// Updated: 07 May 2024
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
		str20(comparator) str10(adjustment) ///
		ptime_covid num_events_covid  /// 
		ptime_comparator num_events_comparator hr lc uc ///
		using $tabfigdir/cox_model_summary, replace
		
foreach an in 2020_pneumonia 2021_pneumonia 2022_pneumonia 2023_pneumonia 2024_pneumonia 2020_general_2019 2021_general_2019 2022_general_2019 2023_general_2019 2024_general_2019 general_2020 general_2021 general_2022 general_2023 general_2024 {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

* Encode smoking status and ethnicity
encode smoking_status, gen(smoking_category)

* Crude
global crude i.case
* Age and sex adjusted
global age_sex i.case i.male age1 age2 age3
* Age, sex, region, imd WITH ETHNICITY
global demo_eth i.case i.male age1 age2 age3 i.ethnicity i.region_9 i.imd
* Demographics + clinical WITH ETHNICITY
global demo_eth_clinical i.case i.male age1 age2 age3 i.ethnicity i.region_9 i.imd /// 
						 i.obese i.smoking_category i.hypertension ///
						 i.diabetes i.chronic_resp_dis i.asthma i.chronic_cardiac_dis ///
						 i.lung_cancer i.haem_cancer i.other_cancer i.chronic_liver_dis ///
						 i.other_neuro i.organ_transplant i.dysplenia i.hiv ///
						 i.permanent_immunodef i.ra_sle_psoriasis


stset sick_note_end_date, id(new_patient_id) failure(sick_note) enter(indexdate) origin(indexdate)
		
foreach adjust in crude age_sex demo_eth demo_eth_clinical  {
	stcox $`adjust', vce(robust)

		matrix b = r(table)
		local hr = b[1,2]
		local lc = b[5,2] 
		local uc = b[6,2]

		stptime if case == 1
		local ptime_covid = `r(ptime)'
		local events_covid .
		local events_covid round(`r(failures)'/ 7 ) * 7
			
		stptime if case == 0
		local ptime_comparator = `r(ptime)'
		local events_comparator .
		local events_comparator round(`r(failures)'/ 7 ) * 7

		post `measures'  ("`an'") ("`adjust'")  ///
			(`ptime_covid') (`events_covid') (`ptime_comparator') (`events_comparator')  ///
			(`hr') (`lc') (`uc')

	}
}

postclose `measures'	

* Change postfiles to csv
use $tabfigdir/cox_model_summary, replace

export delimited using $tabfigdir/cox_model_summary.csv, replace

log close
