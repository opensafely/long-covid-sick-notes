################################################################
# This script:
# - Creates frequency table for all demographic/clinical 
#    covariates by cohort 
#
# Author: Andrea Schaffer
################################################################

library(haven)
library(tidyverse)
library(reshape2)
library(tools)
library(here)
library(fs)
library(RColorBrewer)

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/long-covid-sick-notes")
# getwd()


## Create directories if needed
dir_create(here::here("output", "tabfig"), showWarnings = FALSE, recurse = TRUE)


##### Read in data for each cohort #####

covid20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta"))
covidhosp20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) %>%
  subset(!is.na("hosp_expo_date"))

covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta"))
covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  subset(!is.na("hosp_expo_date"))

pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta"))

gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta"))
gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta"))
gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta"))


###### Function to calculate number of people with each diagnosis #####

# Factorise ----
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}

# Frequencies for each demographic/clinical variable
freq <- function(cohort, var, name) {
    
      cohort %>% 
        mutate(total = n(),
               age_group = fct_case_when(
                 age_group == 1 ~ "0-17 y",
                 age_group == 2 ~ "18-24 y",
                 age_group == 3 ~ "25-34 y",
                 age_group == 4 ~ "35-44 y",
                 age_group == 5 ~ "45-54 y",
                 age_group == 6 ~ "55-69 y",
                 age_group == 7 ~ "70-79 y",
                 age_group == 8 ~ "80 y"
               ),
               male = fct_case_when(
                 male == 1 ~ "Male",
                 male == 0 ~ "Female",
                 TRUE ~ NA_character_
               ),
               ethnicity = fct_case_when(
                 ethnicity == 1 ~ "White",
                 ethnicity == 2 ~ "Mixed",
                 ethnicity == 3 ~ "Asian or Asian British",
                 ethnicity == 4 ~ "Black",
                 ethnicity == 5 ~ "Other",
                 ethnicity == 6 ~ "Unknown",
                 TRUE ~ NA_character_
               ),
               region_9 = fct_case_when(
                 region_9 == 1 ~ "East Midlands",
                 region_9 == 2 ~ "East",
                 region_9 == 3 ~ "London",
                 region_9 == 4 ~ "North East",
                 region_9 == 5 ~ "North West",
                 region_9 == 6 ~ "South East",
                 region_9 == 7 ~ "South West",
                 region_9 == 8 ~ "West Midlands",
                 region_9 == 9 ~ "Yorkshire and The Humber",
                 TRUE ~ NA_character_
               ),
               imd = fct_case_when(
                 imd == 1 ~ "1 (most deprived)",
                 imd == 2 ~ "2",
                 imd == 3 ~ "3",
                 imd == 4 ~ "4",
                 imd == 5 ~ "5 (least deprived)"
               ),
               smoking_status = fct_case_when(
                 smoking_status == "S" ~ "Current smoker",
                 smoking_status == "E" ~ "Former smoker",
                 smoking_status == "N" ~ "Never smoker",
                 smoking_status == "M" ~ "Missing",
                 TRUE ~ NA_character_
               ),
               asthma = fct_case_when(
                 asthma == "0" ~ "No",
                 asthma == "1" ~ "Asthma, predisolone=0 or >4",
                 asthma == "2" ~ "Asthma, prednisolone>0 and <5",
                 TRUE ~ NA_character_
               )
        ) %>%
        group_by(total) %>%
        count({{var}}) %>%
        rename(category = {{var}}) %>%
        mutate(variable = name, category = as.factor(category),
               n = round(n / 7) * 7,
               total = round(total / 7) * 7,
               pcent = n / total * 100) 
     
}

# Combine frequencies for all variable for table
combine <- function(cohort) {
  comb <- rbind( 
    freq(cohort, age_group, "Age group"),
    freq(cohort, male, "Sex"),
    freq(cohort, ethnicity, "Ethnicity"),
    freq(cohort, region_9, "Region"),
    freq(cohort, imd, "IMD"),
    
    freq(cohort, diabetes, "Diabetes"),
    freq(cohort, chronic_resp_dis, "Chronic respiratory disease"),
    freq(cohort, obese, "Obesity"),
    freq(cohort, hypertension, "Hypertension"),
    freq(cohort, asthma, "Asthma"),
    
    freq(cohort, chronic_cardiac_dis, "Chronic cardiac disease"),
    freq(cohort, lung_cancer, "Lung cancer"),
    freq(cohort, haem_cancer, "Haematological cancer"),
    freq(cohort, other_cancer, "Other cancer"),
    freq(cohort, chronic_liver_dis, "Chronic liver disease"),
    
    freq(cohort, other_neuro, "Other neurological disease"),
    freq(cohort, organ_transplant, "Organ transplant"),
    freq(cohort, dysplenia, "Dysplenia"),
    freq(cohort, hiv, "HIV"),
    freq(cohort, permanent_immunodef, "Other permanent immunodeficiency"),
    
    freq(cohort, ra_sle_psoriasis, "RA/SLE/psoriasis"),
    freq(cohort, smoking_status, "Smoking status")
  ) 

}


##### Create separate table/csv file for each cohort #####

table1_covid2020 <- combine(covid20)
write.csv(table1_covid2020, here::here("output", "tabfig", "table1_covid_2020.csv"),
                                       row.names = FALSE)

table1_covid2021 <- combine(covid21)
write.csv(table1_covid2020, here::here("output", "tabfig", "table1_covid_2021.csv"),
                                       row.names = FALSE)
          
table1_covidhosp2020 <- combine(covidhosp20)
write.csv(table1_covidhosp2020, here::here("output", "tabfig", "table1_covid_hosp_2020.csv"),
          row.names = FALSE)

table1_covidhosp2021 <- combine(covidhosp21)
write.csv(table1_covid2020, here::here("output", "tabfig", "table1_covid_hosp_2021.csv"),
          row.names = FALSE)

table1_pneumo2019 <- combine(pneumo19)
write.csv(table1_pneumo2019, here::here("output", "tabfig", "table1_pneumo_2019.csv"),
          row.names = FALSE)

table1_gen2019 <- combine(gen19)
write.csv(table1_gen2019, here::here("output", "tabfig", "table1_gen_2019.csv"),
          row.names = FALSE)

table1_gen2020 <- combine(gen20)
write.csv(table1_gen2020, here::here("output", "tabfig", "table1_gen_2020.csv"),
          row.names = FALSE)

table1_gen2021 <- combine(gen21)
write.csv(table1_gen2021, here::here("output", "tabfig", "table1_gen_2021.csv"),
          row.names = FALSE)