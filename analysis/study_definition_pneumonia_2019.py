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
        AND (age >=18 AND age < 65)
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

    pneumonia_admission_date=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=pneumonia_codelist,
        between=["2019-02-01", "2019-11-30"],
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2019-02-01"}, "incidence": 0.15},
    ),
    
    patient_index_date=patients.minimum_of("pneumonia_admission_date"),
    **demographic_variables,
    **clinical_variables,
    **outcome_variables
)
