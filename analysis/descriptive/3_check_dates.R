################################################################
# This script:
# - Checks if dates makes sense
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
read <- function(data){
  read_dta(here::here("output","cohorts",data)) %>%
    mutate(
        sick_note_end_date = as.Date(sick_note_end_date, format = "%Y-%m-%d"),
        indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
        end_month  = floor_date(as.Date(sick_note_end_date), unit="month"),
        index_month =  floor_date(as.Date(indexdate), unit="month")
          ) %>% 
  dplyr::select(c(patient_id, end_month, index_month, sick_note)) 

}

covid20 <- read("cohort_rates_covid_2020.dta")
covid21 <- read("cohort_rates_covid_2021.dta")
covid22 <- read("cohort_rates_covid_2022.dta")
pneumo19 <- read("cohort_rates_pneumonia_2019.dta")
gen19 <- read("cohort_rates_matched_2019.dta") 
gen20 <- read("cohort_rates_matched_2020.dta") 
gen21 <- read("cohort_rates_matched_2021.dta") 
gen22 <- read("cohort_rates_matched_2022.dta") 


###### Create distribution of end dates #########
tab <- function(data) {
    end <- data %>%
      mutate(total = n()) %>%
      arrange(end_month, sick_note) %>%
      group_by(sick_note, end_month, total) %>%
      summarise(n_end = n()) %>%
      rename(month = end_month) %>%
      mutate(n_end = case_when(n_end > 5 ~ n_end),
             n_end = round(n_end / 7) * 7)
    
    index <- data %>%
      mutate(total = n()) %>%
      arrange(index_month, sick_note) %>%
      group_by(sick_note, index_month, total) %>%
      summarise(n_index = n()) %>%
      rename(month = index_month) %>%
      mutate(n_index = case_when(n_index > 5 ~ n_index),
             n_index = round(n_index / 7) * 7,)
    
    both <- merge(end, index, by = c("month","total","sick_note"))
    
    return(both)
    
}



####### Save files ##########

covid20_tab <- tab(covid20)
write_csv(covid20_tab, here::here("output", "tabfig", "dates_covid20.csv"))

covid21_tab <- tab(covid21)
write_csv(covid21_tab, here::here("output", "tabfig", "dates_covid21.csv"))

covid22_tab <- tab(covid22)
write_csv(covid22_tab, here::here("output", "tabfig", "dates_covid22.csv"))

pneumo19_tab <- tab(pneumo19)
write_csv(pneumo19_tab, here::here("output", "tabfig", "dates_pneumo19.csv"))

gen19_tab <- tab(gen19)
write_csv(gen19_tab, here::here("output", "tabfig", "dates_gen19.csv"))

gen20_tab <- tab(gen20)
write_csv(gen20_tab, here::here("output", "tabfig", "dates_gen20.csv"))

gen21_tab <- tab(gen21)
write_csv(gen21_tab, here::here("output", "tabfig", "dates_gen21.csv"))

gen22_tab <- tab(gen22)
write_csv(gen22_tab, here::here("output", "tabfig", "dates_gen22.csv"))

