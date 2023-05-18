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

covid20 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_general_2019.dta")) %>%
  subset(case == 1) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covidhosp20 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_pneumonia.dta")) %>%
  subset(case == 1) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covid21 <- read_dta(here::here("output", "cohorts", "combined_covid_2021_general_2019.dta")) %>%
  subset(case == 1)%>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

covidhosp21 <- read_dta(here::here("output", "cohorts", "combined_covid_2021_pneumonia.dta")) %>%
  subset(case == 1) %>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

pneumo19 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_pneumonia.dta")) %>%
  subset(case ==0)%>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen19 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_general_2019.dta")) %>%
  subset(case ==0)%>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen20 <- read_dta(here::here("output", "cohorts", "combined_covid_general_2020.dta")) %>%
  subset(case ==0)%>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))

gen21 <- read_dta(here::here("output", "cohorts", "combined_covid_general_2021.dta")) %>%
  subset(case ==0)%>%
  mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
         died_date_ons = as.Date(died_date_ons,format = "%Y-%m-%d"),
         sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"))


###### Number who died #####
died <- function(dat, cohort, enddate){
  
  enddate = as.Date(enddate)
  
  dat2 <- dat %>% 
    mutate(died = if_else(!is.na(died_date_ons) & 
                            died_date_ons == sick_note_end_date, 1, 0, 0),
           time = as.integer(sick_note_end_date - indexdate),
           cohort = cohort,
           indexmissing = if_else(is.na(indexdate), 1, 0, 0),
           endmissing = if_else(is.na(sick_note_end_date), 1, 0, 0)) %>%
    group_by(cohort) %>%
    summarise(n = n(),
              n_died = sum(died),
              n_indexmiss = sum(indexmissing),
              n_endmiss = sum(endmissing),
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
              died(gen20, "General pop 2020","2020-11-30"),
              died(gen21, "General pop 2021", "2021-11-30"),
              died(gen19, "General pop 2019", "2019-11-30")
              ) %>%
  mutate(n = case_when(n > 5 ~ n),
         n = round(n / 7) * 7,
         n_died = case_when(n_died > 5 ~ n_died),
         n_died = round(n_died / 7) * 7,
         pcent = n_died / n * 100)
  

write.csv(all, here::here("output", "tabfig", "check_died.csv"))
