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


###### Check original variables #######

library(data.table)
covid20 <- fread(here::here("output", "cohorts", "input_covid_2020.csv.gz"))
covid21 <- fread(here::here("output", "cohorts", "input_covid_2021.csv.gz"))
pneumo19 <- fread(here::here("output", "cohorts", "input_pneumonia_2019.csv.gz"))
gen19 <- fread(here::here("output", "cohorts", "input_matched_2019.csv.gz"))
gen20 <- fread(here::here("output", "cohorts", "input_matched_2020.csv.gz"))
gen21 <- fread(here::here("output", "cohorts", "input_matched_2021.csv.gz"))


miss_raw <- function(data, name) {
  
  sicknote1  <- data %>%
    subset(!is.na(sick_note_1_date)) %>%
    transmute( n_sick_note = n(),
               notmiss_dur_days = sum(!is.na(sick_note_1_duration_days)),
               notmiss_dur_weeks = sum(!is.na(sick_note_1_duration_weeks)),
               notmiss_dur_mos = sum(!is.na(sick_note_1_duration_months)),
               group = name, var = 1) %>%
    distinct()
  
  sicknote2  <- data %>%
    subset(!is.na(sick_note_2_date)) %>%
    transmute( n_sick_note = n(),
               notmiss_dur_days = sum(!is.na(sick_note_2_duration_days)),
               notmiss_dur_weeks = sum(!is.na(sick_note_2_duration_weeks)),
               notmiss_dur_mos = sum(!is.na(sick_note_2_duration_months)),
               group = name, var = 2) %>%
    distinct()
  
  sicknote3  <- data %>%
    subset(!is.na(sick_note_3_date)) %>%
    transmute( n_sick_note = n(),
               notmiss_dur_days = sum(!is.na(sick_note_3_duration_days)),
               notmiss_dur_weeks = sum(!is.na(sick_note_3_duration_weeks)),
               notmiss_dur_mos=  sum(!is.na(sick_note_3_duration_months)),
               group = name, var = 3) %>%
    distinct()
  
   sicknote4  <- data %>%
    subset(!is.na(sick_note_4_date)) %>%
    transmute( n_sick_note = n(),
               notmiss_dur_days = sum(!is.na(sick_note_4_duration_days)),
               notmiss_dur_weeks = sum(!is.na(sick_note_4_duration_weeks)),
               notmiss_dur_mos = sum(!is.na(sick_note_4_duration_months)),
               group = name, var = 4) %>%
     distinct()
    
    sicknote5 <- data %>%
    subset(!is.na(sick_note_5_date)) %>%
    transmute( n_sick_note = n(),
               notmiss_dur_days = sum(!is.na(sick_note_5_duration_days)),
               notmiss_dur_weeks = sum(!is.na(sick_note_5_duration_weeks)),
               notmiss_dur_mos = sum(!is.na(sick_note_5_duration_months)),
               group = name, var = 5) %>%
      distinct()
  
    sicknotes <- rbind(sicknote1, sicknote2, sicknote3, sicknote4, sicknote5) %>%
      mutate(pcent_dur_days = notmiss_dur_days / n_sick_note * 100,
             pcent_dur_weeks = notmiss_dur_weeks / n_sick_note * 100,
             pcent_dur_mos = notmiss_dur_mos / n_sick_note * 100)
 
    return(sicknotes)
}

missing_all <- rbind(miss_raw(covid20, "COVID2020"),
                     miss_raw(covid21, "COVID2021"),
                     miss_raw(pneumo19, "Pneumo2019"),
                     miss_raw(gen19, "General2019"),
                     miss_raw(gen20, "General2020"),
                     miss_raw(gen21, "General2021"))