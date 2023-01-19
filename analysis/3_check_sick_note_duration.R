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
  subset(!is.na(hosp_expo_date))

covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta"))
covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  subset(!is.na(hosp_expo_date))
pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta"))

gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta"))
gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta"))
gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta"))


###### Function to calculate number of sick note information that is missing #####

missing <- function(cohort, name) {
  
  cohort %>%
    transmute(total = n(),
           n_sick_note = sum(sick_note == 1),
           sick_note_1 = sum(!is.na(sick_note_1_date)),
           sick_note_2 = sum(!is.na(sick_note_2_date)),
           sick_note_3 = sum(!is.na(sick_note_3_date)),
           sick_note_4 = sum(!is.na(sick_note_4_date)),
           sick_note_5 = sum(!is.na(sick_note_5_date)),
           sick_note_dur_1 = sum(!is.na(sick_note_1_duration)),
           sick_note_dur_2 = sum(!is.na(sick_note_2_duration)),
           sick_note_dur_3 = sum(!is.na(sick_note_3_duration)),
           sick_note_dur_4 = sum(!is.na(sick_note_4_duration)),
           sick_note_dur_5 = sum(!is.na(sick_note_5_duration)),
           p_sick_note_1 = sick_note_dur_1 / sick_note_1 *100,
           p_sick_note_2 = sick_note_dur_2 / sick_note_2 *100,
           p_sick_note_3 = sick_note_dur_3 / sick_note_3 *100,
           p_sick_note_4 = sick_note_dur_4 / sick_note_4 *100,
           p_sick_note_5 = sick_note_dur_5 / sick_note_5 *100,
           group = name) %>%
    distinct()
}



##### Create separate table/csv file for each cohort #####


miss_covid20 <- missing(covid20, "COVID2020")
miss_covid21 <- missing(covid21, "COVID2021")
miss_covidhosp20 <- missing(covidhosp20, "COVID hospitalised 2020")
miss_covidhosp21 <- missing(covidhosp20, "COVID hospitalised 2021")
miss_pneumo19 <- missing(pneumo19, "Pneumonia19")
miss_gen19 <- missing(gen19, "General2019")
miss_gen20 <- missing(gen20, "General2020")
miss_gen21 <- missing(gen21, "General2021")

miss_all <- rbind(miss_covid20, miss_covid21, miss_covidhosp20,
                  miss_covidhosp21, miss_pneumo19, miss_gen19, miss_gen20,
                  miss_gen21)

write.csv(miss_all, here::here("output", "tabfig", "sick_note_missing.csv"),
          row.names = FALSE)

