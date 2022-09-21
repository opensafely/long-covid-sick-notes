import sys
import pandas as pd
from cohortextractor import expectation_generators
from osmatching_local import match

year = sys.argv[1]
if sys.argv[1] == "2019":
    case_year = "2020"
else:
    case_year = year

match_df = pd.read_csv(f"output/cohorts/input_general_match_vars_{year}-02-01.csv.gz")
match_df["patient_index_date"] = expectation_generators.generate_dates(
    len(match_df), f"{year}-02-01", f"{year}-12-31", "uniform"
)["date"]
match_df.to_csv(
    f"output/cohorts/input_general_{year}_with_index_date.csv.gz", index=False
)

match(
    case_csv=f"input_covid_{case_year}.csv.gz",
    match_csv=f"input_general_{year}_with_index_date.csv.gz",
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
