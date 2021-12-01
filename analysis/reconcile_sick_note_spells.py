import numpy as np
import pandas as pd
from datetime import timedelta
import sys

GROUPING_WINDOW = 14
NUMBER_OF_SICK_NOTES = 5
date_cols = [f"sick_note_{n}_date" for n in range(1, NUMBER_OF_SICK_NOTES + 1)]

df = pd.read_csv(
    f"output/cohorts/{sys.argv[2]}{sys.argv[1]}.csv",
    index_col="patient_id",
    parse_dates=date_cols,
)
# df = df.set_index("patient_id")

## Convert all durations to days
mask = df.columns.str.contains(".*_weeks")
df.loc[:, mask] = df.loc[:, mask] * 7
mask = df.columns.str.contains(".*_months")
df.loc[:, mask] = df.loc[:, mask] * 30
# print(df["sick_note_1_duration_weeks"])

for n in range(1, 6):
    duration_cols = [
        f"sick_note_{n}_duration_days",
        f"sick_note_{n}_duration_weeks",
        f"sick_note_{n}_duration_months",
    ]
    # Missing values are returned as 0, so need to be replaced with NaN
    df[duration_cols] = df[duration_cols].replace(0, np.nan)
    # In case there are records in two different units:
    df[f"sick_note_{n}_duration"] = df[duration_cols].mean(axis=1)
    df = df.drop(columns=duration_cols)


## Link up contiguous spells for the first sick note spell
##  - those within 7 days of each other


def get_end_date(sick_note_date, n):
    """
    Adds the duration for a given sick note to the start date for that sick note,
    then also adds the specified number of GROUPING_WINDOW days.
    """
    return (
        sick_note_date
        + pd.to_timedelta(df[f"sick_note_{n}_duration"], unit="d")
        + pd.to_timedelta(GROUPING_WINDOW, unit="d")
    )


def replace_with_new_end_date(end_date, n):
    """
    Modifies the supplied end date where the next sick note spell start is before the
    currently defined end date.
    """
    mask = (df[f"sick_note_{n}_date"] <= end_date) & (
        df[f"sick_note_{n}_date"]
        > (spell_end_date - pd.to_timedelta(GROUPING_WINDOW, unit="d"))
    )
    spell_end_date.loc[mask] = get_end_date(df.loc[mask, f"sick_note_{n}_date"], n)
    return end_date


spell_end_date = get_end_date(df["sick_note_1_date"], 1)

for n in range(2, NUMBER_OF_SICK_NOTES):
    spell_end_date = replace_with_new_end_date(spell_end_date, n)

## Count
df["first_sick_note_duration"] = (spell_end_date - df["sick_note_1_date"]).dt.days
# Remove trailing grouping window
df["first_sick_note_duration"] = df["first_sick_note_duration"] - GROUPING_WINDOW


df.to_csv(f"output/cohorts/input{sys.argv[1]}_with_duration.csv")
