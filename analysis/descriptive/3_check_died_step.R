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
gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019_TEST.dta")) 

gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020_TEST.dta")) 

gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021_TEST.dta")) 


###### Number who died and follow-up time #####
died <- function(dat, cohort, enddate){
  
  enddate <- as.Date(enddate)
  
  dat2 <- dat %>% 
    mutate(indexdate = as.Date(indexdate, format = "%Y-%m-%d"),
           died_date_ons = as.Date(died_date_ons, format = "%Y-%m-%d"),
           died_any = if_else(!is.na(died_date_ons) &
                                died_date_ons >= indexdate &
                                died_date_ons <= enddate, 1, 0, 0),
           cohort = cohort) %>%
    group_by(cohort) %>%
    summarise(n = n(),
              n_died_any = sum(died_any))
  
  return(dat2)

}


###### Apply function to each cohort and combine into one ######
all <- rbind(
              died(gen20, "General pop 2020", "2020-11-30"),
              died(gen21, "General pop 2021", "2021-11-30"),
              died(gen19, "General pop 2019", "2019-11-30")
              ) %>%
  mutate(n = case_when(n > 5 ~ n),
         n = round(n / 7) * 7,
         
         n_died_any = case_when(n_died_any > 5 ~ n_died_any),
         n_died_any = round(n_died_any / 7) * 7,
         
         pcent_any = n_died_any / n * 100)
  
# Save
write.csv(all, here::here("output", "tabfig", "check_died.csv"))


# Check death date
dat1 <- gen19 %>%
  group_by(died_date_ons) %>%
  summarise(n = n())
write.csv(dat1, here::here("output", "tabfig", "check_died_gen2019.csv"))


dat2 <- gen20 %>%
  group_by(died_date_ons) %>%
  summarise(n = n()) 
write.csv(dat2, here::here("output", "tabfig", "check_died_gen2020.csv"))


dat3 <- gen21 %>%
  group_by(died_date_ons) %>%
  summarise(n = n())
write.csv(dat3, here::here("output", "tabfig", "check_died_gen2021.csv"))

