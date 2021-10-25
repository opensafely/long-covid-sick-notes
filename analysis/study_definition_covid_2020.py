from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    codelist,
    combine_codelists,
    codelist_from_csv,
)

from codelists import *

from common_variables import generate_common_variables

outcome_variables, demographic_variables, clinical_variables = generate_common_variables(
    index_date_variable="patient_index_date")

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
    population=patients.satisfying(
        """
            has_follow_up
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        AND NOT covid_classification = "0"
        AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "patient_index_date - 1 year", "patient_index_date"
        ),
    ),
    index_date="2020-02-01",
    # COVID infection
    sgss_positive=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    primary_care_covid=patients.with_these_clinical_events(
        any_primary_care_code,
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    hospital_covid=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codes,
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    icu_admission=patients.admitted_to_icu(
        find_first_match_in_period=True,
        on_or_after="index_date",
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    patient_index_date=patients.minimum_of(
        "sgss_positive", "primary_care_covid", "hospital_covid"
    ),
    covid_diagnosis_date=patients.minimum_of(
        "sgss_positive", "primary_care_covid", "hospital_covid"
    ),
    covid_classification=patients.categorised_as(
        {
            "0": "DEFAULT",
            "positive test": "sgss_positive AND NOT hospital_covid",
            "primary care only": """
                                    primary_care_covid
                                    AND NOT sgss_positive
                                    AND NOT hospital_covid
                                """,
            "hospitalised": "hospital_covid AND NOT icu_admission",
            "critical care": "hospital_covid AND icu_admission",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "positive test": 0.6,
                    "primary care only": 0.1,
                    "hospitalised": 0.2,
                    "critical care": 0.1,
                }
            },
        },
    ),
    **demographic_variables,
    **clinical_variables,
    **outcome_variables
)
