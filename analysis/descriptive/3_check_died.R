###############################################################
# This script:
# - Calculates number of people who died, and median/IQR follow-up time by cohort
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
  subset(!is.na(hosp_expo_date) & hosp_expo_date < sick_note_end_date)

covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) 

covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  subset(!is.na(hosp_expo_date) & hosp_expo_date < sick_note_end_date) 

pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta")) 

gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta")) 

gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta")) 

gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta")) 


###### Number who died and follow-up time #####
died <- function(dat, cohort, enddate){
  
  enddate <- as.Date(enddate)
  
  dat2 <- dat %>% 
    mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
           died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
           sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"),
           
           died_censor = if_else(!is.na(died_date_ons) & 
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
  
# Save
write.csv(all, here::here("output", "tabfig", "check_died.csv"))


#########################################################################

# Check earlier datasets to find source of issue

##### Read in data for each cohort #####
gen19 <- read.csv(here::here("output", "cohorts", "input_matched_2019_with_duration.csv")) 

gen20 <- read.csv(here::here("output", "cohorts", "input_matched_2020_with_duration.csv")) 

gen21 <- read.csv(here::here("output", "cohorts", "input_matched_2021_with_duration.csv")) 


###### Number who died and follow-up time #####
died2 <- function(dat, cohort, enddate){
  
  enddate <- as.Date(enddate)
  
  dat2 <- dat %>% 
    mutate(patient_index_date = as.Date(patient_index_date, format = "%Y-%m-%d"),
           died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
           died_any = if_else(!is.na(died_date_ons) &
                                died_date_ons >= patient_index_date &
                                died_date_ons <= enddate, 1, 0, 0),
           indexmissing = if_else(is.na(patient_index_date), 1, 0, 0),
           cohort = cohort,) %>%
    group_by(cohort) %>%
    summarise(n = n(),
              n_died_any = sum(died_any),
              n_indexmiss = sum(indexmissing))
  
  return(dat2)
  
}


###### Apply function to each cohort and combine into one ######
all <- rbind(
  died2(gen20, "General pop 2020", "2020-11-30"),
  died2(gen21, "General pop 2021", "2021-11-30"),
  died2(gen19, "General pop 2019", "2019-11-30")
) %>%
  mutate(n = case_when(n > 5 ~ n),
         n = round(n / 7) * 7,
         
         n_died_any = case_when(n_died_any > 5 ~ n_died_any),
         n_died_any = round(n_died_any / 7) * 7,
         
         pcent_any = n_died_any / n * 100)

# Save
write.csv(all, here::here("output", "tabfig", "check_died_input.csv"))


# Check death date
dat1 <- gen19 %>%
  group_by(died_date_ons) %>%
  summarise(n = n())
write.csv(dat1, here::here("output", "tabfig", "check_ons_dates_gen2019.csv"))


dat2 <- gen20 %>%
  group_by(died_date_ons) %>%
  summarise(n = n()) 
write.csv(dat2, here::here("output", "tabfig", "check_ons_dates_gen2020.csv"))


dat3 <- gen21 %>%
    group_by(died_date_ons) %>%
    summarise(n = n())
write.csv(dat3, here::here("output", "tabfig", "check_ons_dates_gen2021.csv"))


# Check index date
dat1 <- gen19 %>%
  group_by(patient_index_date) %>%
  summarise(n = n()) 
write.csv(dat1, here::here("output", "tabfig", "check_index_dates_gen2019.csv"))


dat2 <- gen20 %>%
  group_by(patient_index_date) %>%
  summarise(n = n()) 
write.csv(dat2, here::here("output", "tabfig", "check_index_dates_gen2020.csv"))


dat3 <- gen21 %>%
  group_by(patient_index_date) %>%
  summarise(n = n())
write.csv(dat3, here::here("output", "tabfig", "check_index_dates_gen2021.csv"))


# Check deregistered date
dat1 <- gen19 %>%
  group_by(deregistered) %>%
  summarise(n = n()) 
write.csv(dat1, here::here("output", "tabfig", "check_deregister_dates_gen2019.csv"))


dat2 <- gen20 %>%
  group_by(deregistered) %>%
  summarise(n = n()) 
write.csv(dat2, here::here("output", "tabfig", "check_deregister_dates_gen2020.csv"))


dat3 <- gen21 %>%
  group_by(deregistered) %>%
  summarise(n = n())
write.csv(dat3, here::here("output", "tabfig", "check_deregister_dates_gen2021.csv"))
