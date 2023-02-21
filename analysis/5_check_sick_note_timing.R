################################################################
# This script:
# - Checks if end date makes sense
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
library(lubridate)

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/long-covid-sick-notes")
# getwd()


## Create directories if needed
dir_create(here::here("output", "tabfig"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "cohorts"), showWarnings = FALSE, recurse = TRUE)


##### Read in data for each cohort #####
read <- function(data, cohort){
  read_dta(here::here("output","cohorts",data)) %>%
    mutate(
        sick_note_1_date = as.Date(sick_note_1_date, format = "%Y-%m-%d"),
        sick_note_2_date = as.Date(sick_note_2_date, format = "%Y-%m-%d"),
        sick_note_3_date = as.Date(sick_note_3_date, format = "%Y-%m-%d"),
        sick_note_4_date = as.Date(sick_note_4_date, format = "%Y-%m-%d"),
        sick_note_5_date = as.Date(sick_note_5_date, format = "%Y-%m-%d"),
        group = cohort
          ) %>% 
  dplyr::select(c(patient_id, group, indexdate, 
                  sick_note_1_date,
                  sick_note_2_date, sick_note_3_date,
                  sick_note_4_date, sick_note_5_date)) %>%
  melt(id = c("patient_id", "indexdate", "group"),  
       value.name = "date", na.rm = TRUE) %>%
  mutate(date = as.Date(date, format = "%Y-%m-%d", origin = "1970-01-01"),
           time = as.numeric(date - indexdate),
           time_gp = ifelse(time >=0 & time <30, "<30 days",
                            ifelse(time >=30 & time <90, "30-89 days",
                            ifelse(time >=90 & time <150, "90-149 days", "150+ days")))) %>%
  group_by(group, time_gp) %>%
    summarise(cnt = n()) 
}

covid20 <- read("cohort_rates_covid_2020.dta", "COVID20")
covid21 <- read("cohort_rates_covid_2021.dta", "COVID21")
gen19 <- read("cohort_rates_matched_2019.dta", "General19") 
gen20 <- read("cohort_rates_matched_2020.dta", "General20") 
gen21 <- read("cohort_rates_matched_2021.dta", "General21")                                                  
                       
all <- rbind(covid20, covid21, gen19, gen20, gen21)


####### Save files ##########
write_csv(all, here::here("output", "tabfig", "sick_notes_all_over_time.csv"))



##### Read in data for each cohort #####
read2 <- function(data, cohort){
  read_dta(here::here("output","cohorts",data)) %>%
    mutate(
      sick_note_1_date = as.Date(sick_note_1_date, format = "%Y-%m-%d"),
      group = cohort
    ) %>% 
    dplyr::select(c(patient_id, group, indexdate, 
                    sick_note_1_date)) %>%
    melt(id = c("patient_id", "indexdate", "group"),  
         value.name = "date", na.rm = TRUE) %>%
    mutate(date = as.Date(date, format = "%Y-%m-%d", origin = "1970-01-01"),
           time = as.numeric(date - indexdate),
           time_gp = ifelse(time >=0 & time <30, "<30 days",
                            ifelse(time >=30 & time <90, "30-89 days",
                                   ifelse(time >=90 & time <150, "90-149 days", "150+ days")))) %>%
    group_by(group, time_gp) %>%
    summarise(cnt = n()) 
}

covid20 <- read2("cohort_rates_covid_2020.dta", "COVID20")
covid21 <- read2("cohort_rates_covid_2021.dta", "COVID21")
gen19 <- read2("cohort_rates_matched_2019.dta", "General19") 
gen20 <- read2("cohort_rates_matched_2020.dta", "General20") 
gen21 <- read2("cohort_rates_matched_2021.dta", "General21")                                                  

all2 <- rbind(covid20, covid21, gen19, gen20, gen21)


####### Save files ##########
write_csv(all2, here::here("output", "tabfig", "sick_notes_first_over_time.csv"))




