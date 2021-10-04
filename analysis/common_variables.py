from cohortextractor import patients, codelist, filter_codes_by_category, combine_codelists
from codelists import *
from datetime import datetime, timedelta

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
            "index_date",
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
                "index_date",
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
        previous_covid=patients.categorised_as(
            {
                "COVID positive": """
                                    (sgss_positive OR primary_care_covid)
                                    AND NOT hospital_covid
                                    """,
                "COVID hospitalised": "hospital_covid",
                "No COVID code": "DEFAULT",
            },
            return_expectations={
                "incidence": 1,
                "category": {
                    "ratios": {
                        "COVID positive": 0.4,
                        "COVID hospitalised": 0.4,
                        "No COVID code": 0.2,
                    }
                },
            },
        ),
    )

    clinical_variables = dict(
        efrailty=patients.with_these_decision_support_values(
            "electronic_frailty_index",
            on_or_before=f"{index_date_variable}",
            find_last_match_in_period=True,
            returning="numeric_value",
            return_expectations={
                "float": {"distribution": "normal", "mean": 0.2, "stddev": 0.005}
            },
        ),
        emergency_care=patients.attended_emergency_care(
            on_or_before=f"{index_date_variable} - 1 month",
            returning="binary_flag",
            return_expectations={"incidence": 0.2},
        ),
        previous_sick_note=patients.with_these_clinical_events(
            sick_notes_codes,
            on_or_before=f"{index_date_variable} - 1 month",
            return_expectations={"incidence": 0.2},
        ),
        bmi=patients.most_recent_bmi(
            on_or_after=f"{index_date_variable} - 10 year",
            minimum_age_at_measurement=16,
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "incidence": 0.98,
                "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            },
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
                on_or_before=f"{index_date_variable} - 1 day",
            ),
            smoked_last_18_months=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=[f"{index_date_variable} - 548 day", f"{index_date_variable}"],
            ),
        ),
        hypertension=patients.with_these_clinical_events(
            hypertension_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        diabetes=patients.with_these_clinical_events(
            diabetes_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
            hba1c_new_codes,
            find_last_match_in_period=True,
            between=[f"{index_date_variable} - 730 day", f"{index_date_variable}"],
            returning="numeric_value",
            include_date_of_match=False,
            return_expectations={
                "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
                "incidence": 0.98,
            },
        ),
        hba1c_percentage_1=patients.with_these_clinical_events(
            hba1c_old_codes,
            find_last_match_in_period=True,
            between=[f"{index_date_variable} - 730 day", f"{index_date_variable}"],
            returning="numeric_value",
            include_date_of_match=False,
            return_expectations={
                "float": {"distribution": "normal", "mean": 5, "stddev": 2},
                "incidence": 0.98,
            },
        ),
        chronic_respiratory_disease=patients.with_these_clinical_events(
            chronic_respiratory_disease_codes,
            return_first_date_in_period=True,
            include_month=True,
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
                ) AND (
                    prednisolone_last_year = 0 OR 
                    prednisolone_last_year > 4
                )
            """,
                "2": """
                (
                    recent_asthma_code OR (
                    asthma_code_ever AND NOT
                    copd_code_ever
                    )
                ) AND
                prednisolone_last_year > 0 AND
                prednisolone_last_year < 5
                
            """,
            },
            return_expectations={
                "category": {"ratios": {"0": 0.8, "1": 0.1, "2": 0.1}},
            },
            recent_asthma_code=patients.with_these_clinical_events(
                asthma_codes,
                between=["2017-02-01", "2020-02-01"],
            ),
            asthma_code_ever=patients.with_these_clinical_events(asthma_codes),
            copd_code_ever=patients.with_these_clinical_events(
                chronic_respiratory_disease_codes
            ),
            prednisolone_last_year=patients.with_these_medications(
                pred_codes,
                between=["2019-02-01", "2020-02-01"],
                returning="number_of_matches_in_period",
            ),
        ),
        chronic_cardiac_disease=patients.with_these_clinical_events(
            chronic_cardiac_disease_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        lung_cancer=patients.with_these_clinical_events(
            lung_cancer_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        haem_cancer=patients.with_these_clinical_events(
            haem_cancer_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        other_cancer=patients.with_these_clinical_events(
            other_cancer_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        chronic_liver_disease=patients.with_these_clinical_events(
            chronic_liver_disease_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        other_neuro=patients.with_these_clinical_events(
            other_neuro,
            return_first_date_in_period=True,
            include_month=True,
        ),
        dementia=patients.with_these_clinical_events(
            dementia,
            return_first_date_in_period=True,
            include_month=True,
        ),
        stroke_for_dementia_defn=patients.with_these_clinical_events(
            stroke_for_dementia_defn,
            return_first_date_in_period=True,
            include_month=True,
        ),
        organ_transplant=patients.with_these_clinical_events(
            organ_transplant_codes,
            return_first_date_in_period=True,
            include_month=True,
            ),
        dysplenia=patients.with_these_clinical_events(
            spleen_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        sickle_cell=patients.with_these_clinical_events(
            sickle_cell_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        aplastic_anaemia=patients.with_these_clinical_events(
            aplastic_codes,
            return_last_date_in_period=True,
            include_month=True,
        ),
        hiv=patients.with_these_clinical_events(
            hiv_codes,
            returning="category",
            find_first_match_in_period=True,
            include_date_of_match=True,
            include_month=True,
            return_expectations={
                "category": {"ratios": {"43C3.": 0.8, "XaFuL": 0.2}},
            },
        ),
        permanent_immunodeficiency=patients.with_these_clinical_events(
            permanent_immune_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        temporary_immunodeficiency=patients.with_these_clinical_events(
            temp_immune_codes,
            return_last_date_in_period=True,
            include_month=True,
        ),
        bp_sys=patients.mean_recorded_value(
            systolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before="2020-02-01",
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 80, "stddev": 10},
                "date": {"latest": "2020-02-29"},
                "incidence": 0.95,
            },
        ),
        bp_dias=patients.mean_recorded_value(
            diastolic_blood_pressure_codes,
            on_most_recent_day_of_measurement=True,
            on_or_before="2020-02-01",
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 120, "stddev": 10},
                "date": {"latest": "2020-02-29"},
                "incidence": 0.95,
            },
        ),
        ra_sle_psoriasis=patients.with_these_clinical_events(
            ra_sle_psoriasis_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),    
    )
    return outcome_variables, demographic_variables, clinical_variables 
