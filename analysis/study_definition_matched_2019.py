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

MATCHES = "output/cohorts/matched_matches_general_2019.csv"

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

    **demographic_variables,
    **clinical_variables,
    **outcome_variables
)
