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
dir_create(here::here("output", "cohorts"), showWarnings = FALSE, recurse = TRUE)


##### Read in data for each cohort #####
# 
# covid20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) 
# covidhosp20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) %>%
#   subset(!is.na(hosp_expo_date))
# 
# covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta"))
# covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
#   subset(!is.na(hosp_expo_date))
# pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta"))
# 
# gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta"))
# gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta"))
# gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta"))
# 
# 
# ###### Function to calculate number of sick note information that is missing #####
# 
# missing <- function(cohort, name) {
# 
#   cohort %>%
#     transmute(total = n(),
#            n_sick_note = sum(sick_note == 1),
#            sick_note_dur = sum(!is.na(first_sick_note_duration)),
#            group = name) %>%
#     distinct()
# }
# 
# 
# ##### Create separate table/csv file for each cohort #####
# 
# 
# miss_covid20 <- missing(covid20, "COVID2020")
# miss_covid21 <- missing(covid21, "COVID2021")
# miss_covidhosp20 <- missing(covidhosp20, "COVID hospitalised 2020")
# miss_covidhosp21 <- missing(covidhosp20, "COVID hospitalised 2021")
# miss_pneumo19 <- missing(pneumo19, "Pneumonia19")
# miss_gen19 <- missing(gen19, "General2019")
# miss_gen20 <- missing(gen20, "General2020")
# miss_gen21 <- missing(gen21, "General2021")
# 
# miss_all <- rbind(miss_covid20, miss_covid21, miss_covidhosp20,
#                   miss_covidhosp21, miss_pneumo19, miss_gen19, miss_gen20,
#                   miss_gen21)
# 
# write.csv(miss_all, here::here("output", "tabfig", "sick_note_missing.csv"),
#           row.names = FALSE)
# 

###### Check original variables #######

# Load data
library(data.table)
covid20 <- fread(here::here("output", "cohorts", "input_covid_2020.csv.gz")) %>%
  subset(!is.na(sick_note_1_date))
covid21 <- fread(here::here("output", "cohorts", "input_covid_2021.csv.gz"))%>%
  subset(!is.na(sick_note_1_date)) 
pneumo19 <- fread(here::here("output", "cohorts", "input_pneumonia_2019.csv.gz")) %>%
  subset(!is.na(sick_note_1_date))
gen19 <- fread(here::here("output", "cohorts", "input_matched_2019.csv.gz")) %>%
  subset(!is.na(sick_note_1_date))
gen20 <- fread(here::here("output", "cohorts", "input_matched_2020.csv.gz")) %>%
  subset(!is.na(sick_note_1_date))
gen21 <- fread(here::here("output", "cohorts", "input_matched_2021.csv.gz")) %>%
  subset(!is.na(sick_note_1_date))


# Function to calculate proportion where duration is missing
# among people with a first sick note
miss_raw <- function(data, name) {

  data %>%
    mutate(all_miss = ((sick_note_1_duration_days == 0|is.na(sick_note_1_duration_days)) &
                         (sick_note_1_duration_weeks == 0|is.na(sick_note_1_duration_weeks)) &
                         (sick_note_1_duration_months == 0|is.na(sick_note_1_duration_months)))) %>%
    transmute( n_sick_note = n(),
               miss_dur_days = sum(sick_note_1_duration_days == 0|is.na(sick_note_1_duration_days)) ,
               miss_dur_weeks = sum(sick_note_1_duration_weeks == 0|is.na(sick_note_1_duration_weeks)) ,
               miss_dur_mos = sum(sick_note_1_duration_months == 0|is.na(sick_note_1_duration_months)),
               miss_dur_all = sum(all_miss),
               group = name) %>%
    distinct() %>%
    mutate(pcent_dur_days = miss_dur_days / n_sick_note * 100,
             pcent_dur_weeks = miss_dur_weeks / n_sick_note * 100,
             pcent_dur_mos = miss_dur_mos / n_sick_note * 100,
             pcent_dur_all = miss_dur_all / n_sick_note * 100)


}


missing_all <- rbind(miss_raw(covid20, "COVID2020"),
                     miss_raw(covid21, "COVID2021"),
                     miss_raw(pneumo19, "Pneumo2019"),
                     miss_raw(gen19, "General2019"),
                     miss_raw(gen20, "General2020"),
                     miss_raw(gen21, "General2021"))

write.csv(missing_all, here::here("output", "tabfig", "sick_note_missing_raw.csv"),
          row.names = FALSE)


# Function to calculate frequency distribution of duration variables
miss_raw_gp <- function(data, name) {
  
  days <- data %>% 
    mutate(n_sick_note = n(),
           days_gp = ifelse(sick_note_1_duration_days > 0,
                            ceiling(sick_note_1_duration_days / 7), 0)) %>%
    group_by(days_gp, n_sick_note) %>%
    summarise(n = n()) %>%
    mutate(group = name, period = "Days",
           pcent = n / n_sick_note * 100) %>%
    rename(category = days_gp ) 

  weeks <- data %>% 
      mutate(n_sick_note = n(),
             weeks_gp = ceiling(sick_note_1_duration_weeks)) %>%
      group_by(weeks_gp, n_sick_note) %>%
      tally(weeks_gp) %>%
      mutate(group = name, period = "Weeks",
             pcent = n / n_sick_note * 100) %>%
      rename(category = weeks_gp )
    
  months <- data %>% 
      mutate(n_sick_note = n(),
             months_gp = ceiling(sick_note_1_duration_months)) %>%
      group_by(months_gp, n_sick_note) %>%
      tally(months_gp) %>%
      mutate(group = name, period = "Months",
             pcent = n / n_sick_note * 100) %>%
      rename(category = months_gp )
      
  all <- rbind(days, weeks, months)
  
  return(all)
  
}


missing_cat_all <- rbind(miss_raw_gp(covid20, "COVID2020"),
                         miss_raw_gp(covid21, "COVID2021"),
                         miss_raw_gp(pneumo19, "Pneumo2019"),
                         miss_raw_gp(gen19, "General2019"),
                         miss_raw_gp(gen20, "General2020"),
                         miss_raw_gp(gen21, "General2021"))

write.csv(missing_cat_all, here::here("output", "tabfig", "sick_note_missing_raw_gp.csv"),
          row.names = FALSE)




