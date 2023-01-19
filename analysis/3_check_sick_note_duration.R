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
           sick_note_dur = sum(!is.na(first_sick_note_duration)),
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


##### Overwrite old files   #####

tmp <- subset(miss_all, group == "tmp") %>% dplyr::select(group)

write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_covid20.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_covid21.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_covidhosp20.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_covidhosp21.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_pneumo19.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_gen20.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_gen19.csv"),
          row.names = FALSE)
write.csv(tmp, here::here("output", "tabfig", "sick_note_missing_gen21.csv"),
          row.names = FALSE)


