###############################################################
# This script:
# - Calculates number of people in each diagnosis category
#     within each cohort and visualises the results
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

covid20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covidhosp20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) %>%
  subset(!is.na(hosp_expo_date) &
           hosp_expo_date < sick_note_end_date) %>%
  mutate(indexdate = hosp_expo_date,
         indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  subset(!is.na(hosp_expo_date) &
           hosp_expo_date < sick_note_end_date) %>%
  mutate(indexdate = hosp_expo_date,
         indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta")) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))


###### Number who died #####
died <- function(dat, cohort, enddate){
  
  enddate <- as.Date(enddate)
  
  dat2 <- dat %>% 
    mutate(died_censor = if_else(!is.na(died_date_ons) & 
                            died_date_ons == sick_note_end_date - 1, 1, 0, 0),
           died_any = if_else(!is.na(died_date_ons) &
                                died_date_ons >= indexdate &
                                died_date_ons <= enddate, 1, 0, 0),
           time = as.integer(sick_note_end_date - indexdate),
           cohort = cohort) %>%
    group_by(cohort) %>%
    summarise(n = n(),
              n_died_any = sum(died_any),
              n_died_censor = sum(died_censor),
              median_time = median(time, na.rm = TRUE),
              q25 = quantile(time, 0.25, na.rm = TRUE), 
              q75 = quantile(time, 0.75, na.rm = TRUE))
  
  return(dat2)

}


###### Apply function to each cohort and combine into one ######
all <- rbind(
              died(covid20, "COVID 2020", "2020-11-30"),
              died(covid21, "COVID 2021", "2021-11-30"),
              died(covidhosp20, "COVID hospitalised 2020", "2020-11-30"),
              died(covidhosp21, "COVID hospitalised 2021", "2021-11-30"),
              died(pneumo19, "Pneumonia 2019", "2019-11-30"),
              died(gen20, "General pop 2020", "2020-11-30"),
              died(gen21, "General pop 2021", "2021-11-30"),
              died(gen19, "General pop 2019", "2019-11-30")
              ) %>%
  mutate(n = case_when(n > 5 ~ n),
         n = round(n / 7) * 7,
         
         n_died_any = case_when(n_died_any > 5 ~ n_died_any),
         n_died_any = round(n_died_any / 7) * 7,
         
         n_died_censor = case_when(n_died_censor > 5 ~ n_died_censor),
         n_died_censor = round(n_died_censor / 7) * 7,
         
         pcent_any = n_died_any / n * 100,
         pcent_censor = n_died_censor / n *100)
  

write.csv(all, here::here("output", "tabfig", "check_died.csv"))
