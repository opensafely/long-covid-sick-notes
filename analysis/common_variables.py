from cohortextractor import patients, codelist
from codelists import *


outcome_variables = dict(
    sick_note_1_date=patients.with_these_clinical_events(
        sick_notes_codes,
        on_or_after="patient_index_date",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "incidence": 0.9,
            "date": {"earliest": "index_date"},
        },
    ),
    **{
        f"sick_note_{n}_date": patients.with_these_clinical_events(
            sick_notes_codes,
            on_or_after=f"sick_note_{n-1}_date + 1 day",
            find_first_match_in_period=True,
            returning="date",
            date_format="YYYY-MM-DD",
            return_expectations={
                "incidence": 0.9,
                "date": {"earliest": "index_date"},
            },
        )
        for n in range(2, 6)
    },
    **{
        f"sick_note_{n}_duration_days": patients.with_these_clinical_events(
            codelist(["Y1712"], system="ctv3"),
            between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
            returning="numeric_value",
            return_expectations={
                "incidence": 0.9,
                "float": {"distribution": "normal", "mean": 21, "stddev": 5},
            },
        )
        for n in range(1, 6)
    },
    **{
        f"sick_note_{n}_duration_weeks": patients.with_these_clinical_events(
            codelist(["Y08c1"], system="ctv3"),
            between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
            returning="numeric_value",
            return_expectations={
                "incidence": 0.9,
                "float": {"distribution": "normal", "mean": 21, "stddev": 5},
            },
        )
        for n in range(1, 6)
    },
    **{
        f"sick_note_{n}_duration_months": patients.with_these_clinical_events(
            codelist(["Y08c2"], system="ctv3"),
            between=[f"sick_note_{n}_date", f"sick_note_{n}_date"],
            returning="numeric_value",
            return_expectations={
                "incidence": 0.9,
                "float": {"distribution": "normal", "mean": 21, "stddev": 5},
            },
        )
        for n in range(1, 6)
    },
)

demographic_variables = dict(
    age=patients.age_as_of(
        "patient_index_date",
        return_expectations={
        "rate": "universal",
        "int": {"distribution": "population_ages"},
        },
        ),
    age_group=patients.categorised_as(
        {
            "0-17": "age < 18",
            "18-24": "age >= 18 AND age < 25",
            "25-34": "age >= 25 AND age < 35",
            "35-44": "age >= 35 AND age < 45",
            "45-54": "age >= 45 AND age < 55",
            "55-69": "age >= 55 AND age < 70",
            "70-79": "age >= 70 AND age < 80",
            "80+": "age >= 80",
            "missing": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0-17": 0.1,
                    "18-24": 0.1,
                    "25-34": 0.1,
                    "35-44": 0.1,
                    "45-54": 0.2,
                    "55-69": 0.2,
                    "70-79": 0.1,
                    "80+": 0.1,
                }
            },
        },
    ),
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """
                    index_of_multiple_deprivation >=1
                AND index_of_multiple_deprivation < 32844*1/5
                """,
            "2": """
                    index_of_multiple_deprivation >= 32844*1/5
                AND index_of_multiple_deprivation < 32844*2/5
                """,
            "3": """
                    index_of_multiple_deprivation >= 32844*2/5
                AND index_of_multiple_deprivation < 32844*3/5
                """,
            "4": """
                    index_of_multiple_deprivation >= 32844*3/5
                AND index_of_multiple_deprivation < 32844*4/5
                """,
            "5": """
                    index_of_multiple_deprivation >= 32844*4/5
                AND index_of_multiple_deprivation < 32844
                 """,
        },
        index_of_multiple_deprivation=patients.address_as_of(
            "index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                }
            },
        },
    ),
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="patient_index_date",
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    previous_covid=patients.categorised_as(
        {
            "COVID positive": """
                                (sgss_positive OR primary_care_covid)
                                AND NOT hospital_covid
                                """,
            "COVID hospitalised": "hospital_covid",
            "No COVID code": "DEFAULT",
        },
        return_expectations={
            "incidence": 1,
            "category": {
                "ratios": {
                    "COVID positive": 0.4,
                    "COVID hospitalised": 0.4,
                    "No COVID code": 0.2,
                }
            },
        },
    ),
)

clinical_variables = dict(
    efrailty=patients.with_these_decision_support_values(
        "electronic_frailty_index",
        on_or_before="patient_index_date",
        find_last_match_in_period=True,
        returning="numeric_value",
        return_expectations={
            "float": {"distribution": "normal", "mean": 0.2, "stddev": 0.005}
        },
    ),
    emergency_care=patients.attended_emergency_care(
        on_or_before="patient_index_date - 1 month",
        returning="binary_flag",
        return_expectations={"incidence": 0.2},
    ),
    previous_sick_note=patients.with_these_clinical_events(
        sick_notes_codes,
        on_or_before="patient_index_date - 1 month",
        return_expectations={"incidence": 0.2},
    ),
)
