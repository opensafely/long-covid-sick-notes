################################################################
# This script:
# - Creates frequency table of COVID diagnosis type
#   (SGSS test, primary care, hospital diagnosis)
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
  subset(case == 1)

covid21 <- read_dta(here::here("output", "cohorts", "combined_covid_2021_general_2019.dta")) %>%
  subset(case == 1)

covid22 <- read_dta(here::here("output", "cohorts", "combined_covid_2022_general_2019.dta")) %>%
  subset(case == 1)



# Frequencies for COVID diagnosis type
covid_type <- function(cohort, name) {
    
      cohort1 <- cohort %>% 
        mutate(total = n(),
               sgss = if_else(indexdate == sgss_positive & !is.na(sgss_positive),
                              1, 0, 0),
               primarycare = if_else(indexdate == primary_care_covid_date & !is.na(primary_care_covid_date),
                              1, 0, 0),
               hospital = if_else(indexdate == hospital_covid_date & !is.na(hospital_covid_date),
                              1, 0, 0)) 
  
  # Counts within each variable category
  counts <- cohort1 %>%
    group_by(total) %>%
    summarise(sgss = sum(sgss),
              primarycare = sum(primarycare),
              hospital = sum(hospital)) %>%
    mutate(# Rounding and redaction
          total = case_when(total > 5 ~ total),
           total = round(total / 7) * 7,
          sgss = case_when(sgss > 5 ~ sgss),
           sgss = round(sgss / 7) * 7,
          primarycare = case_when(primarycare > 5 ~ primarycare),
            primarycare = round(primarycare / 7) * 7,
          hospital = case_when(hospital > 5 ~ hospital),
            hospital = round(hospital / 7) * 7,
          
          pcent_sgss = sgss / total * 100,
          pcent_primarycare = primarycare / total * 100,
          pcent_hospital = hospital / total * 100,
          
          cohort = name)

  return(counts)
}


covid_all <- rbind(covid_type(covid20, "COVID2020"),
                   covid_type(covid21, "COVID2021"),
                   covid_type(covid22, "COVID2022"))


##### Create separate table/csv file for each cohort #####
write.csv(covid_all, here::here("output", "tabfig", "table_covid_type.csv"))