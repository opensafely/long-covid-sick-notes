import sys
import pandas as pd
from osmatching_local import match

year = sys.argv[1]
gen_pop_df = pd.read_csv(f"output/cohorts/input_general_{year}.csv")
gen_pop_df["patient_index_date"] = f"{year}-02-01"
gen_pop_df.to_csv(
    f"output/cohorts/input_general_{year}_with_index_date.csv", index=False
)

if sys.argv[1] == "2019":
    match(
        case_csv=f"input_covid_2020.csv",
        match_csv=f"input_general_{year}_with_index_date.csv",
        matches_per_case=5,
        match_variables={
            "sex": "category",
            "age": 1,
            "stp": "category",
        },
        closest_match_variables=["age"],
        index_date_variable="patient_index_date",
        output_suffix=f"_general_{year}",
        output_path="output/cohorts",
        input_path="output/cohorts",
        matching_type="frequency",
    )
else:
    match(
        case_csv=f"input_covid_{year}.csv",
        match_csv=f"input_general_{year}_with_index_date.csv",
        matches_per_case=5,
        match_variables={
            "sex": "category",
            "age": 1,
            "stp": "category",
        },
        closest_match_variables=["age"],
        index_date_variable="patient_index_date",
        output_suffix=f"_general_{year}",
        output_path="output/cohorts",
        input_path="output/cohorts",
        matching_type="frequency",
    )