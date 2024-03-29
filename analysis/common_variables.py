from cohortextractor import (
    patients,
    codelist,
    filter_codes_by_category,
    combine_codelists,
)
from codelists import *
from variable_loop import get_codelist_variable

variables = {
    "diag_central_nervous_system": [central_nervous_system_codes],
    "diag_pregnancy_complication": [pregnancy_complication_codes],
    "diag_congenital_disease": [congenital_disease_codes],
    "diag_auditory_disorder": [auditory_disorder_codes],
    "diag_cardio_disorder": [cardio_disorder_codes],
    "diag_bloodcell_disorder": [bloodcell_disorder_codes],
    "diag_connective_tissue": [connective_tissue_disorder_codes],
    "diag_digestive_disorder": [digestive_disorder_codes],
    "diag_endocrine_disorder": [endocrine_disorder_codes],
    "diag_fetus_newborn_disorder": [fetus_newborn_disorder_codes],
    "diag_hematopoietic_disorder": [hematopoietic_disorder_codes],
    "diag_immune_disorder": [immune_disorder_codes],
    "diag_labor_delivery_disorder": [labor_delivery_disorder_codes],
    "diag_musculoskeletal_disorder": [musculoskeletal_disorder_codes],
    "diag_nervous_disorder": [nervous_disorder_codes],
    "diag_puerperium_disorder": [puerperium_disorder_codes],
    "diag_respiratory_disorder": [respiratory_disorder_codes],
    "diag_skin_disorder": [skin_disorder_codes],
    "diag_genitourinary_disorder": [genitourinary_disorder_codes],
    "diag_infectious_disease": [infectious_disease_codes],
    "diag_mental_disorder": [mental_disorder_codes],
    "diag_metabolic_disease": [metabolic_disease_codes],
    "diag_neoplastic_disease": [neoplastic_disease_codes],
    "diag_nutritional_disorder": [nutritional_disorder_codes],
    "diag_poisoning": [poisoning_codes],
    "diag_trauma": [trauma_codes],
    "diag_visual_disorder": [visual_disorder_codes],
}

covariates = {k: get_codelist_variable(v) for k, v in variables.items()}

def generate_common_variables(index_date_variable):

    outcome_variables = dict(
        sick_note_1_date=patients.with_these_clinical_events(
            sick_notes_codes,
            on_or_after=f"{index_date_variable}",
            find_first_match_in_period=True,
            returning="date",
            date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.9,
                "date": {"earliest": "index_date"},
            },
        ),
        **{
            f"sick_note_{n}_date": patients.with_these_clinical_events(
                sick_notes_codes,
                on_or_after=f"sick_note_{n-1}_date + 1 day",
                find_first_match_in_period=True,
                returning="date",
                date_format="YYYY-MM-DD",
                return_expectations={
                    "incidence": 0.9,
                    "date": {"earliest": "index_date"},
                },
            )
            for n in range(2, 6)
        },
        **{
            f"sick_note_{n}_duration_days": patients.with_these_clinical_events(
                codelist(["Y1712"], system="ctv3"),
                between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
                returning="numeric_value",
                return_expectations={
                    "incidence": 0.9,
                    "float": {"distribution": "normal", "mean": 21, "stddev": 5},
                },
            )
            for n in range(1, 6)
        },
        **{
            f"sick_note_{n}_duration_weeks": patients.with_these_clinical_events(
                codelist(["Y08c1"], system="ctv3"),
                between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
                returning="numeric_value",
                return_expectations={
                    "incidence": 0.9,
                    "float": {"distribution": "normal", "mean": 21, "stddev": 5},
                },
            )
            for n in range(1, 6)
        },
        **{
            f"sick_note_{n}_duration_months": patients.with_these_clinical_events(
                codelist(["Y08c2"], system="ctv3"),
                between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
                returning="numeric_value",
                return_expectations={
                    "incidence": 0.9,
                    "float": {"distribution": "normal", "mean": 21, "stddev": 5},
                },
            )
            for n in range(1, 6)
        },
        **covariates,
    )

    demographic_variables = dict(
        age=patients.age_as_of(
            f"{index_date_variable}",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
        age_group=patients.categorised_as(
            {
                "0-17": "age < 18",
                "18-24": "age >= 18 AND age < 25",
                "25-34": "age >= 25 AND age < 35",
                "35-44": "age >= 35 AND age < 45",
                "45-54": "age >= 45 AND age < 55",
                "55-69": "age >= 55 AND age < 70",
                "70-79": "age >= 70 AND age < 80",
                "80+": "age >= 80",
                "missing": "DEFAULT",
            },
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "0-17": 0.1,
                        "18-24": 0.1,
                        "25-34": 0.1,
                        "35-44": 0.1,
                        "45-54": 0.2,
                        "55-69": 0.2,
                        "70-79": 0.1,
                        "80+": 0.1,
                    }
                },
            },
        ),
        sex=patients.sex(
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {"M": 0.49, "F": 0.51}},
            }
        ),
        stp=patients.registered_practice_as_of(
             f"{index_date_variable}",
            returning="stp_code",
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "STP1": 0.1,
                        "STP2": 0.1,
                        "STP3": 0.1,
                        "STP4": 0.1,
                        "STP5": 0.1,
                        "STP6": 0.1,
                        "STP7": 0.1,
                        "STP8": 0.1,
                        "STP9": 0.1,
                        "STP10": 0.1,
                    }
                },
            },
        ),
        practice_id=patients.registered_practice_as_of(
            f"{index_date_variable}",
            returning="pseudo_id",
            return_expectations={
                "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
                "incidence": 1,
            },
        ),
        region=patients.registered_practice_as_of(
            f"{index_date_variable}",
            returning="nuts1_region_name",
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "North East": 0.1,
                        "North West": 0.1,
                        "Yorkshire and The Humber": 0.1,
                        "East Midlands": 0.1,
                        "West Midlands": 0.1,
                        "East": 0.1,
                        "London": 0.2,
                        "South East": 0.1,
                        "South West": 0.1,
                    },
                },
            },
        ),
        imd=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": """
                        index_of_multiple_deprivation >=1
                    AND index_of_multiple_deprivation < 32844*1/5
                    """,
                "2": """
                        index_of_multiple_deprivation >= 32844*1/5
                    AND index_of_multiple_deprivation < 32844*2/5
                    """,
                "3": """
                        index_of_multiple_deprivation >= 32844*2/5
                    AND index_of_multiple_deprivation < 32844*3/5
                    """,
                "4": """
                        index_of_multiple_deprivation >= 32844*3/5
                    AND index_of_multiple_deprivation < 32844*4/5
                    """,
                "5": """
                        index_of_multiple_deprivation >= 32844*4/5
                    AND index_of_multiple_deprivation < 32844
                    """,
            },
            index_of_multiple_deprivation=patients.address_as_of(
                f"{index_date_variable}",
                returning="index_of_multiple_deprivation",
                round_to_nearest=100,
            ),
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "0": 0.05,
                        "1": 0.19,
                        "2": 0.19,
                        "3": 0.19,
                        "4": 0.19,
                        "5": 0.19,
                    }
                },
            },
        ),
        ethnicity=patients.with_these_clinical_events(
            ethnicity_codes,
            returning="category",
            find_last_match_in_period=True,
            on_or_before=f"{index_date_variable}",
            return_expectations={
                "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
                "incidence": 0.75,
            },
        ),
        died_date_ons=patients.died_from_any_cause(
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            return_expectations={
                "date": {"earliest": "index_date"},
                "incidence": 0.1,
            },
        ),
        deregistered=patients.date_deregistered_from_all_supported_practices(
            date_format="YYYY-MM-DD",
            return_expectations={
                "date": {"earliest": "index_date"},
                "incidence": 0.5,
            },
        ),
    )

    clinical_variables = dict(
        emergency_care=patients.attended_emergency_care(
            on_or_before=f"{index_date_variable} - 1 day",
            returning="binary_flag",
            return_expectations={"incidence": 0.2},
        ),
        previous_sick_note=patients.with_these_clinical_events(
            sick_notes_codes,
            on_or_before=f"{index_date_variable} - 1 day",
            returning="binary_flag",
            include_date_of_match=True,
            find_last_match_in_period=True,
            date_format="YYYY-MM-DD",
            return_expectations={"incidence": 0.2},
        ),
        obese=patients.satisfying(
            """
            bmi >= 30
            """,
            bmi=patients.most_recent_bmi(
                between=[
                    f"{index_date_variable} - 10 year",
                    f"{index_date_variable} - 1 day",
                ],
                minimum_age_at_measurement=16,
            ),
        ),
        smoking_status=patients.categorised_as(
            {
                "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
                "E": """
                        (most_recent_smoking_code = 'E' OR (
                        most_recent_smoking_code = 'N' AND ever_smoked
                        )
                        ) AND NOT smoked_last_18_months
                """,
                "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
                "M": "DEFAULT",
            },
            return_expectations={
                "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
            },
            most_recent_smoking_code=patients.with_these_clinical_events(
                clear_smoking_codes,
                find_last_match_in_period=True,
                on_or_before=f"{index_date_variable} - 1 day",
                returning="category",
            ),
            ever_smoked=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                returning="binary_flag",
                on_or_before=f"{index_date_variable} - 1 day",
            ),
            smoked_last_18_months=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=[f"{index_date_variable} - 548 day", f"{index_date_variable}"],
            ),
        ),
        hypertension=patients.with_these_clinical_events(
            hypertension_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        diabetes=patients.with_these_clinical_events(
            diabetes_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
            hba1c_new_codes,
            find_last_match_in_period=True,
            between=[
                f"{index_date_variable} - 730 day",
                f"{index_date_variable} - 1 day",
            ],
            returning="numeric_value",
            return_expectations={
                "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
                "incidence": 0.98,
            },
        ),
        hba1c_percentage_1=patients.with_these_clinical_events(
            hba1c_old_codes,
            find_last_match_in_period=True,
            between=[
                f"{index_date_variable} - 730 day",
                f"{index_date_variable} - 1 day",
            ],
            returning="numeric_value",
            return_expectations={
                "float": {"distribution": "normal", "mean": 5, "stddev": 2},
                "incidence": 0.98,
            },
        ),
        chronic_resp_dis=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        asthma=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": """
                (
                    recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                    )
                )
                """,
            },
            return_expectations={
                "category": {"ratios": {"0": 0.8, "1": 0.2}},
            },
            asthma_code_ever=patients.with_these_clinical_events(
                asthma_codes,
                returning="binary_flag",
                on_or_before=f"{index_date_variable} - 1 day",
            ),
            recent_asthma_code=patients.with_these_clinical_events(
                asthma_codes,
                returning="binary_flag",
                between=[
                    f"{index_date_variable} - 3 year",
                    f"{index_date_variable} - 1 day",
                ],
            ),
            copd_code_ever=patients.with_these_clinical_events(
                chronic_respiratory_disease_codes,
                on_or_before=f"{index_date_variable} - 1 day",
            ),
        ),
        chronic_cardiac_dis=patients.with_these_clinical_events(
            chronic_cardiac_disease_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        lung_cancer=patients.with_these_clinical_events(
            lung_cancer_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        haem_cancer=patients.with_these_clinical_events(
            haem_cancer_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        other_cancer=patients.with_these_clinical_events(
            other_cancer_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        chronic_liver_dis=patients.with_these_clinical_events(
            chronic_liver_disease_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        other_neuro=patients.with_these_clinical_events(
            other_neuro,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        organ_transplant=patients.with_these_clinical_events(
            organ_transplant_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        dysplenia=patients.with_these_clinical_events(
            spleen_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        hiv=patients.with_these_clinical_events(
            hiv_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        permanent_immunodef=patients.with_these_clinical_events(
            permanent_immune_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        temporary_immunodef=patients.with_these_clinical_events(
            temp_immune_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
        ),
        bp_sys=patients.mean_recorded_value(
            systolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before=f"{index_date_variable} - 1 day",
            return_expectations={
                "float": {"distribution": "normal", "mean": 80, "stddev": 10},
                "incidence": 0.95,
            },
        ),
        bp_dias=patients.mean_recorded_value(
            diastolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before=f"{index_date_variable} - 1 day",
            return_expectations={
                "float": {"distribution": "normal", "mean": 120, "stddev": 10},
                "incidence": 0.95,
            },
        ),
        ra_sle_psoriasis=patients.with_these_clinical_events(
            ra_sle_psoriasis_codes,
            returning="binary_flag",
            on_or_before=f"{index_date_variable} - 1 day",
            include_date_of_match=True,
            find_last_match_in_period=True,
            date_format="YYYY-MM-DD",
        ),
    )
    return outcome_variables, demographic_variables, clinical_variables
