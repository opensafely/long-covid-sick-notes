################################################################
# This script:
# - Checks that all index dates are after hospitalisation dates
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
library(readr)

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/long-covid-sick-notes")
# getwd()


## Create directories if needed
dir_create(here::here("output", "tabfig"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "cohorts"), showWarnings = FALSE, recurse = TRUE)


##### Check for index dates prior to hospitalisation dates for each cohort

covid20 <- read_csv(here::here("output", "cohorts", "input_covid_2020_with_duration.csv"),
                    col_types = cols (
                      hospital_covid = col_date(format = "%Y-%m-%d"),
                      patient_index_date = col_date(format = "%Y-%m-%d"),
                      sgss_positive = col_date(format = "%Y-%m-%d"),
                      primary_care_covid = col_date(format = "%Y-%m-%d")
                    )) %>%
  dplyr::select(c(patient_id, patient_index_date, hospital_covid, sgss_positive,
                  primary_care_covid)) %>%
  subset((patient_index_date < as.Date("2020-11-01"))|is.na(patient_index_date)) %>%
  mutate(n = n()) %>%
  # Only select people where the hospitalisation was the first recorded COVID event
  subset(!is.na(hospital_covid) &
          (
            is.na(sgss_positive) | 
              (hospital_covid <= sgss_positive & !is.na(sgss_positive))
          ) &
          (
            is.na(primary_care_covid) | 
              (hospital_covid <= primary_care_covid & !is.na(primary_care_covid))
          )) %>%
  mutate(n_hosp = n(),
          index_before_hosp = ifelse(patient_index_date < hospital_covid, 1, 0),
          los = patient_index_date - hospital_covid + 1,
          group = "COVID2020") %>%
  group_by(n, n_hosp, group) %>%
  summarise(index_before_hosp = sum(index_before_hosp == 1),
            los_p25 = quantile(los, .25, na.rm = TRUE),
            los_median = quantile(los, .5, na.rm = TRUE),
            los_p75 = quantile(los, .75, na.rm = TRUE)) 

covid21 <- read_csv(here::here("output", "cohorts", "input_covid_2021_with_duration.csv"),
                    col_types = cols (
                      hospital_covid = col_date(format = "%Y-%m-%d"),
                      patient_index_date = col_date(format = "%Y-%m-%d"),
                      sgss_positive = col_date(format = "%Y-%m-%d"),
                      primary_care_covid = col_date(format = "%Y-%m-%d")
                    )) %>%
  dplyr::select(c(patient_id, patient_index_date, hospital_covid, sgss_positive,
                  primary_care_covid)) %>%
  subset((patient_index_date < as.Date("2021-11-01"))|is.na(patient_index_date)) %>%
  mutate(n = n()) %>%
  # Only select people where the hospitalisation was the first recorded COVID event
  subset(!is.na(hospital_covid) &
           (
             is.na(sgss_positive) | 
               (hospital_covid <= sgss_positive & !is.na(sgss_positive))
           ) &
           (
             is.na(primary_care_covid) | 
               (hospital_covid <= primary_care_covid & !is.na(primary_care_covid))
           )) %>%
  mutate(n_hosp = n(),
         index_before_hosp = ifelse(patient_index_date < hospital_covid, 1, 0),
         los = patient_index_date - hospital_covid + 1,
         group = "COVID2021") %>%
  group_by(n, n_hosp, group) %>%
  summarise(index_before_hosp = sum(index_before_hosp == 1),
            los_p25 = quantile(los, .25, na.rm = TRUE),
            los_median = quantile(los, .5, na.rm = TRUE),
            los_p75 = quantile(los, .75, na.rm = TRUE)) 

pneumo19 <- read_csv(here::here("output", "cohorts", "input_pneumonia_2019_with_duration.csv"),
                      col_types = cols (
                      pneumonia_admission_date = col_date(format = "%Y-%m-%d"),
                      patient_index_date = col_date(format = "%Y-%m-%d")
                    )) %>%
  dplyr::select(c(patient_id, patient_index_date, pneumonia_admission_date)) %>%
  subset((patient_index_date < as.Date("2019-11-01"))|is.na(patient_index_date)) %>%
  mutate(n = n()) %>%
  subset(!is.na(pneumonia_admission_date)) %>%
  mutate(n_hosp = n(),
         index_before_hosp = ifelse(patient_index_date < pneumonia_admission_date, 1, 0),
         los = patient_index_date - pneumonia_admission_date + 1,
         group = "Pneumonia2019") %>%
  group_by(n, n_hosp, group) %>%
  summarise(index_before_hosp = sum(index_before_hosp == 1),
            los_p25 = quantile(los, .25, na.rm = TRUE),
            los_median = quantile(los, .5, na.rm = TRUE),
            los_p75 = quantile(los, .75, na.rm = TRUE)) 

# Combine
los_all <- rbind(covid20, covid21, pneumo19)

# Save
write.csv(los_all, here::here("output", "tabfig", "los_checks.csv"),
          row.names = FALSE)




