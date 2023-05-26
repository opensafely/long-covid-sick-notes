################################################################
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
dir_create(here::here("output", "cohorts"), showWarnings = FALSE, recurse = TRUE)


##### Read in data for each cohort #####

covid20 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_general_2019.dta")) %>%
  subset(case == 1)
                  
covidhosp20 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_pneumonia.dta")) %>%
  subset(case == 1)

covid21 <- read_dta(here::here("output", "cohorts", "combined_covid_2021_general_2019.dta")) %>%
  subset(case == 1)

covidhosp21 <- read_dta(here::here("output", "cohorts", "combined_covid_2021_pneumonia.dta")) %>%
  subset(case == 1)

covid22 <- read_dta(here::here("output", "cohorts", "combined_covid_2022_general_2019.dta")) %>%
  subset(case == 1)

covidhosp22 <- read_dta(here::here("output", "cohorts", "combined_covid_2022_pneumonia.dta")) %>%
  subset(case == 1)

pneumo19 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_pneumonia.dta")) %>%
  subset(case ==0)

gen19 <- read_dta(here::here("output", "cohorts", "combined_covid_2020_general_2019.dta")) %>%
  subset(case ==0)
gen20 <- read_dta(here::here("output", "cohorts", "combined_covid_general_2020.dta")) %>%
  subset(case ==0)
gen21 <- read_dta(here::here("output", "cohorts", "combined_covid_general_2021.dta")) %>%
  subset(case ==0)
gen22 <- read_dta(here::here("output", "cohorts", "combined_covid_general_2022.dta")) %>%
  subset(case ==0)


###### Function to calculate number of people with each diagnosis #####

diag <- function(cohort, name){
  
cohort %>% dplyr::select(c("patient_id", starts_with("diag_"), "sick_note")) %>%
    
    subset(sick_note == 1 ) %>%
    # Calculate total population for denominator
    mutate(total = n()) %>%
    
    # Count number of diagnosis categories per person - to identify people with no diagnoses
    group_by(patient_id) %>%
    mutate(num_diag = sum(!is.na(across(starts_with("diag_")))),
           diag_none = ifelse(num_diag == 0, 1, NA)) %>%
    ungroup() %>%
    
    # Count total number or people with a non-missing value for each diagnosis category
    group_by(total) %>%
    summarise(across(starts_with("diag_"), ~ sum(!is.na(.x)))) %>%
    
    # Transpose to long
    melt(id = c("total"), value.name = "count", variable.name = "diagnosis") %>%
    
    mutate(# Rounding
           count = case_when(count > 5 ~ count),
           count = round(count / 7) * 7,
           total = case_when(total > 5 ~ total),
           total = round(total / 7) * 7,
           
           # Calculate percent of population + 95%CI with each category
             # (NB: Given the large sample size, these may be too narrow to be 
             # useful)
           pcent =  count / total * 100,
           lci = pcent - (1.96 * sqrt((pcent * (100 - pcent)) / total)),
           uci = pcent + (1.96 * sqrt((pcent * (100 - pcent)) / total)),
           
           # Variable for cohort
           cohort = name, 
           
           # Convert to more readable diagnosis category name
           diagnosis = 
             toTitleCase(str_replace_all(diagnosis, c("diag_" = "", "_" = " "))))

}


###### Apply function to each cohort and combine into one ######

covid2020 <- diag(covid20, "COVID-19 2020")
covid2021 <- diag(covid21, "COVID-19 2021")
covid2022 <- diag(covid22, "COVID-19 2022")

covidhosp2020 <- diag(covidhosp20, "COVID-19 hospitalised 2020")
covidhosp2021 <- diag(covidhosp21, "COVID-19 hospitalised 2021")
covidhosp2022 <- diag(covidhosp22, "COVID-19 hospitalised 2022")

pneumo2019 <- diag(pneumo19, "Pneumonia 2019")

gen2019 <- diag(gen19, "General population 2019")
gen2020 <- diag(gen20, "General population 2020")
gen2021 <- diag(gen21, "General population 2021")
gen2022 <- diag(gen22, "General population 2022")

all_diag <- rbind(covid2020, covid2021, covid22, covidhosp2020, covidhosp2021,
                  covidhosp2022,
                  pneumo2019, gen2019, gen2020, gen2021, gen2022)

# Save
write.csv(all_diag, here::here("output", "tabfig", "diag_by_cohort.csv"),
          row.names = FALSE)


##### Bar chart to visualise results #####

ggplot(subset(all_diag, diagnosis !="None"), aes(x = cohort)) +
  geom_bar(aes(y = pcent, fill = cohort),
           stat = "identity") + 
  geom_errorbar(aes(ymin = lci, ymax = uci), width = 0.2, col = "gray50") +
  scale_fill_manual(values = brewer.pal(8, "Spectral")) +
  ylab("Percentage (%)") + xlab(NULL) +
  facet_wrap(~ diagnosis, scales = "free_y", ncol = 4) + 
  theme(axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(),
        legend.title = element_blank(),
        panel.background = element_rect(fill = "gray95"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        strip.background = element_blank(),
        text = element_text(size = 9))

ggsave(here::here("output", "tabfig", "diag_all.png"), dpi = 300,
       height = 8, width = 8)