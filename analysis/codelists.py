from cohortextractor import codelist, codelist_from_csv, combine_codelists

covid_codes = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)
covid_primary_care_positive_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_sequalae = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system="ctv3",
    column="CTV3ID",
)
any_primary_care_code = combine_codelists(
    covid_primary_care_code,
    covid_primary_care_positive_test,
    covid_primary_care_sequalae,
)
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
sick_notes_codes = codelist_from_csv(
    "codelists/user-alex-walker-sick-notes-ctv3.csv",
    system="ctv3",
    column="code",
)
pneumonia_codelist = codelist_from_csv(
    "codelists/opensafely-pneumonia-secondary-care.csv",
    system="icd10",
    column="ICD code",
)
# Comorbidities
aplastic_codes = codelist_from_csv(
    "codelists/opensafely-aplastic-anaemia.csv", 
    system="ctv3", 
    column="CTV3ID",
)
asthma_codes = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis.csv", 
    system="ctv3", 
    column="CTV3ID",
)
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)
chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv", 
    system="ctv3", 
    column="CTV3ID",
)
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")
diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv",
    system="ctv3",
    column="CTV3ID",
)
haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", 
    system="ctv3", 
    column="CTV3ID",
)
hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv",
    system="ctv3",
    column="CTV3ID",
)
hiv_codes = codelist_from_csv(
    "codelists/opensafely-hiv.csv", 
    system="ctv3", 
    column="CTV3ID", 
    category_column="CTV3ID",
)
ics_codes = codelist_from_csv(
    "codelists/opensafely-asthma-inhaler-steroid-medication.csv",
    system="snomed",
    column="id",
)
lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", 
    system="ctv3", 
    column="CTV3ID",
)
organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)
other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)
permanent_immune_codes = codelist_from_csv(
    "codelists/opensafely-permanent-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)
ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv", 
    system="ctv3", 
    column="CTV3ID",
)
salbutamol_codes = codelist_from_csv(
    "codelists/opensafely-asthma-inhaler-salbutamol-medication.csv",
    system="snomed",
    column="id",
)
sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)
spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv", 
    system="ctv3", 
    column="CTV3ID",
)
stroke_for_dementia_defn = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", 
    system="ctv3", 
    column="CTV3ID",
)
systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
temp_immune_codes = codelist_from_csv(
    "codelists/opensafely-temporary-immunosuppression.csv",
    system="ctv3",
    column="CTV3ID",
)
central_nervous_system_codes = codelist_from_csv(
    "codelists/user-kate-mansfield-central-nervous-system-finding-all-descendants.csv",
    system="snomed",
    column="code",
)
pregnancy_complication_codes = codelist_from_csv(
    "codelists/user-kate-mansfield-complication-of-pregnancy-childbirth-andor-the-puerperium-all-descendants.csv",
    system="snomed",
    column="code",
)
congenital_disease_codes = codelist_from_csv(
    "codelists/user-kate-mansfield-congenital-disease-all-descendants.csv",
    system="snomed",
    column="code",
)
auditory_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-auditory-system-all-descendants.csv",
    system="snomed",
    column="code",
)
cardio_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-cardiovascular-system-all-descendants.csv",
    system="snomed",
    column="code",
)
bloodcell_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-cellular-component-of-blood-all-descendants.csv",
    system="snomed",
    column="code",
)
connective_tissue_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-connective-tissue-all-descendants.csv",
    system="snomed",
    column="code",
)
digestive_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-digestive-system-all-descendants.csv",
    system="snomed",
    column="code",
)
endocrine_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-endocrine-system-all-descendants.csv",
    system="snomed",
    column="code",
)
fetus_newborn_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-fetus-or-newborn-all-descendants.csv",
    system="snomed",
    column="code",
)
hematopoietic_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-hematopoietic-structure-all-descendants.csv",
    system="snomed",
    column="code",
)
immune_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-immune-function-all-descendants.csv",
    system="snomed",
    column="code",
)
labor_delivery_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-labor-delivery-all-descendants.csv",
    system="snomed",
    column="code",
)
musculoskeletal_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-musculoskeletal-system-all-descendants.csv",
    system="snomed",
    column="code",
)
nervous_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-nervous-system-all-descendants.csv",
    system="snomed",
    column="code",
)
puerperium_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-puerperium-all-descendants.csv",
    system="snomed",
    column="code",
)
respiratory_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-respiratory-system-all-descendants.csv",
    system="snomed",
    column="code",
)
skin_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-skin-andor-subcutaneous-tissue-all-descendants.csv",
    system="snomed",
    column="code",
)
genitourinary_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-disorder-of-the-genitourinary-system-all-descendants.csv",
    system="snomed",
    column="code",
)
infectious_disease_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-infectious-disease-all-descendants.csv",
    system="snomed",
    column="code",
)
mental_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-mental-disorder-all-descendants.csv",
    system="snomed",
    column="code",
)
metabolic_disease_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-metabolic-disease-all-descendants.csv",
    system="snomed",
    column="code",
)
neoplastic_disease_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-neoplastic-disease-all-descendants.csv",
    system="snomed",
    column="code",
)
nutritional_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-nutritional-disorder-all-descendants.csv",
    system="snomed",
    column="code",
)
poisoning_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-poisoning-all-descendants.csv",
    system="snomed",
    column="code",
)
trauma_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-traumatic-andor-non-traumatic-injury-all-descendants.csv",
    system="snomed",
    column="code",
)
visual_disorder_codes=codelist_from_csv(
    "codelists/user-kate-mansfield-visual-system-disorder-all-descendants.csv",
    system="snomed",
    column="code",
)
any_symptoms_codes = combine_codelists(
    central_nervous_system_codes,
    pregnancy_complication_codes,
    congenital_disease_codes,
    auditory_disorder_codes,
    cardio_disorder_codes,
    bloodcell_disorder_codes,
    connective_tissue_disorder_codes,
    digestive_disorder_codes,
    endocrine_disorder_codes,
    fetus_newborn_disorder_codes,
    hematopoietic_disorder_codes,
    immune_disorder_codes,
    labor_delivery_disorder_codes,
    musculoskeletal_disorder_codes,
    nervous_disorder_codes,
    puerperium_disorder_codes,
    respiratory_disorder_codes,
    skin_disorder_codes,
    genitourinary_disorder_codes,
    infectious_disease_codes,
    mental_disorder_codes,
    metabolic_disease_codes,
    neoplastic_disease_codes,
    nutritional_disorder_codes,
    poisoning_codes,
    trauma_codes,
    visual_disorder_codes
)