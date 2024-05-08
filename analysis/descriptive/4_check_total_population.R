

################################################################
# This script:
# - Creates frequency table of COVID diagnosis type
#   (SGSS test, primary care, hospital diagnosis)
#
# Author: Andrea Schaffer (updated 07/05/2024 Rose)
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
pop20 <- read_csv(here::here("output", "cohorts", "input_general_match_vars_2020-02-01.csv.gz")) 
pop21 <- read_csv(here::here("output", "cohorts", "input_general_match_vars_2021-02-01.csv.gz")) 
pop22 <- read_csv(here::here("output", "cohorts", "input_general_match_vars_2022-02-01.csv.gz")) 
pop23 <- read_csv(here::here("output", "cohorts", "input_general_match_vars_2023-02-01.csv.gz")) 
pop24 <- read_csv(here::here("output", "cohorts", "input_general_match_vars_2024-02-01.csv.gz")) 


pop20_cnt <- pop20 %>%
  summarise(tot = n()) %>%
  mutate(year = "2020")

pop21_cnt <- pop21 %>%
  summarise(tot = n()) %>%
  mutate(year = "2021")

pop22_cnt <- pop22 %>%
  summarise(tot = n()) %>%
  mutate(year = "2022")

pop23_cnt <- pop23 %>%
  summarise(tot = n()) %>%
  mutate(year = "2023")

pop24_cnt <- pop24 %>%
  summarise(tot = n()) %>%
  mutate(year = "2024")


population_all <- rbind(pop20_cnt, pop21_cnt, pop22_cnt, pop23_cnt, pop24_cnt) %>%
  mutate(tot =round(tot / 7) * 7)

write.csv(population_all, here::here("output","tabfig","population_by_year.csv"),
          row.names = FALSE)