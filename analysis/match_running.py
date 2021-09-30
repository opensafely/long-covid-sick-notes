from osmatching import match
import sys

match(
    case_csv="input_covid_2020",
    match_csv=sys.argv[1],
    matches_per_case=5,
    match_variables={
        "sex": "category",
        "age": 1,
        "stp": "category",
    },
    index_date_variable="patient_index_date",
    output_suffix=sys.argv[2],
    output_path="output/cohorts",
)

