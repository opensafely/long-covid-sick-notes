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

(
    outcome_variables,
    demographic_variables,
    clinical_variables,
) = generate_common_variables(index_date_variable="patient_index_date")

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
        AND pneumonia_admission_date
        AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "pneumonia_admission_date - 1 year", "pneumonia_admission_date"
        ),
    ),
    index_date="2019-02-01",
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
        returning="date_admitted",
    pneumonia_admission_date=patients.admitted_to_hospital(
        with_these_diagnoses=pneumonia_codelist,
        on_or_after="2019-02-01",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2019-02-01"}, "incidence": 0.15},
    ),
    covid_diagnosis_date=patients.minimum_of(
        "sgss_positive", "primary_care_covid", "hospital_covid"
    ),
    patient_index_date=patients.minimum_of(
        "pneumonia_admission_date"
    ),
    **demographic_variables,
    **clinical_variables,
    **outcome_variables
)
