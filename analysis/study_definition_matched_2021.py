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

MATCHES = "output/cohorts/matched_matches_general_2021.csv"

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
    population=patients.which_exist_in_file(MATCHES),
    index_date="2021-01-01",  # Ignored
    patient_index_date=patients.with_value_from_file(
        MATCHES,
        returning="patient_index_date",
        returning_type="date",
    ),
    # COVID infection
    sgss_positive=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        between=["2021-02-01", "2021-11-30"],
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    primary_care_covid=patients.with_these_clinical_events(
        any_primary_care_code,
        between=["2021-02-01", "2021-11-30"],
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    hospital_covid=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codes,
        between=["2021-02-01", "2021-11-30"],
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"incidence": 0.1, "date": {"earliest": "index_date"}},
    ),
    covid_diagnosis_date=patients.minimum_of(
        "sgss_positive", "primary_care_covid", "hospital_covid"
    ),
    **demographic_variables,
    **clinical_variables,
    **outcome_variables
)
