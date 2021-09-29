from osmatching import match

def fn_match(comparator, suffix):
    match(
        case_csv="input",
        match_csv=comparator,
        matches_per_case=5,
        match_variables={
            "sex": "category",
            "age": 1,
        },
        index_date_variable="patient_index_date",
        output_suffix=suffix,
        output_path="output/cohorts",
    )

fn_match("input_general_2019", "_2019")
fn_match("input_general_2020", "_2020")