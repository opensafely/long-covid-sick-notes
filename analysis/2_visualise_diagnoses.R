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


##### Read in data for each cohort #####

covid20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta"))
                    
covidhosp20 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2020.dta")) %>%
  subset(!is.na(hosp_expo_date))

covid21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta"))
covidhosp21 <- read_dta(here::here("output", "cohorts", "cohort_rates_covid_2021.dta")) %>%
  subset(!is.na(hosp_expo_date))

pneumo19 <- read_dta(here::here("output", "cohorts", "cohort_rates_pneumonia_2019.dta"))

gen19 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2019.dta"))
gen20 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2020.dta"))
gen21 <- read_dta(here::here("output", "cohorts", "cohort_rates_matched_2021.dta"))


###### Function to calculate number of people with each diagnosis #####

diag <- function(cohort, name){
  
cohort %>% select(c("patient_id", starts_with("diag_"))) %>%
    
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
           count = round(count / 7) * 7,
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
covidhosp2020 <- diag(covidhosp20, "COVID-19 hospitalised 2020")
covidhosp2021 <- diag(covidhosp21, "COVID-19 hospitalised 2021")
pneumo2019 <- diag(pneumo19, "Pneumonia 2019")

gen2019 <- diag(gen20, "General population 2019")
gen2020 <- diag(gen20, "General population 2020")
gen2021 <- diag(gen20, "General population 2021")

all_diag <- rbind(covid2020, covid2021, covidhosp2020, covidhosp2021,
                  pneumo2019, gen2019, gen2020, gen2021)

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