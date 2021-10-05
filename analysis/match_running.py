from osmatching import match
import sys
import pandas as pd

gen_pop_df = pd.read_csv("output/cohorts/" + sys.argv[1] + ".csv")
gen_pop_df["patient_index_date"] = sys.argv[3]
gen_pop_df.to_csv("output/cohorts/" + sys.argv[1] + "_with_index_date.csv", index=False)

match(
    case_csv="input_covid_2020",
    match_csv=sys.argv[1] + "_with_index_date",
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

