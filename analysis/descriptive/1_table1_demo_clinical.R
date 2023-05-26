################################################################
# This script:
# - Creates frequency table for all demographic/clinical 
#    covariates by cohort 
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

# Factorise ----
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}

# Frequencies for each demographic/clinical variable
freq <- function(cohort, var, name) {
    
      cohort1 <- cohort %>% 
        mutate(total = n(),

               age_group = fct_case_when(
                 age_group == 1 ~ "18-24 y",
                 age_group == 2 ~ "25-34 y",
                 age_group == 3 ~ "35-44 y",
                 age_group == 4 ~ "45-54 y",
                 age_group == 5 ~ "55-64 y",
                 TRUE ~ NA_character_
               ),
               male = fct_case_when(
                 male == 1 ~ "Male",
                 male == 0 ~ "Female",
                 TRUE ~ NA_character_
               ),
               ethnicity = fct_case_when(
                 ethnicity == 1 ~ "White",
                 ethnicity == 2 ~ "Mixed",
                 ethnicity == 3 ~ "Asian or Asian British",
                 ethnicity == 4 ~ "Black",
                 ethnicity == 5 ~ "Other",
                 ethnicity == 6 ~ "Unknown"
               ),
               region_9 = fct_case_when(
                 region_9 == 1 ~ "East Midlands",
                 region_9 == 2 ~ "East",
                 region_9 == 3 ~ "London",
                 region_9 == 4 ~ "North East",
                 region_9 == 5 ~ "North West",
                 region_9 == 6 ~ "South East",
                 region_9 == 7 ~ "South West",
                 region_9 == 8 ~ "West Midlands",
                 region_9 == 9 ~ "Yorkshire and The Humber"
               ),
               imd = fct_case_when(
                 imd == 1 ~ "1 (most deprived)",
                 imd == 2 ~ "2",
                 imd == 3 ~ "3",
                 imd == 4 ~ "4",
                 imd == 5 ~ "5 (least deprived)"
               ),
               smoking_status = fct_case_when(
                 smoking_status == "S" ~ "Current smoker",
                 smoking_status == "E" ~ "Former smoker",
                 smoking_status == "N" ~ "Never smoker",
                 smoking_status == "M" ~ "Missing",
                 TRUE ~ NA_character_
               )
        ) 
  
  # Counts within each variable category
  counts <- cohort1 %>%
    group_by(total) %>%
    count({{var}}) %>%
    rename(category = {{var}}) %>%
    mutate(variable = name, 
          category = as.factor(category),
          # Rounding and redaction
          n = case_when(n > 5 ~ n),
           n = round(n / 7) * 7,
          total = case_when(total > 5 ~ total),
           total = round(total / 7) * 7,
          pcent_total = n / total * 100)
  
  # Number who received a sick note
  summ <- cohort1 %>%
    subset(sick_note == 1) %>% 
    group_by({{var}}) %>%
    summarise( n_sick_note = n()) %>%
    rename(category = {{var}}) %>%
    mutate(n_sick_note = case_when(n_sick_note > 5 ~ n_sick_note),
          n_sick_note = round(n_sick_note / 7) * 7)

  # # Sick note duration
  # summ2 <- cohort1 %>%
  #   subset(sick_note == 1 & !is.na(first_sick_note_duration)) %>%
  #   group_by({{var}}) %>%
  #   summarise(n_sick_note_notmiss = sum(sick_note),
  #       p25_sick_note_duration = quantile(first_sick_note_duration, .25, na.rm = TRUE),
  #       med_sick_note_duration = quantile(first_sick_note_duration, .5, na.rm = TRUE),
  #       p75_sick_note_duration = quantile(first_sick_note_duration, .75, na.rm = TRUE), 
  #       mean_sick_note_duration = mean(first_sick_note_duration, na.rm = TRUE))  %>%
  #   rename(category = {{var}}) 
  
  table <- merge(counts, summ, by = c("category")) %>%
    mutate(pcent_sick_note = n_sick_note / n * 100)
  
  col_order <- c("variable", "category", "n", "total", "pcent_total", "n_sick_note",
                 "pcent_sick_note")
  
  table <- table[, col_order]

  return(table)
}

# Combine frequencies for all variable for table
combine <- function(cohort) {
  comb <- rbind( 
    freq(cohort, age_group, "Age group"),
    freq(cohort, male, "Sex"),
    freq(cohort, ethnicity, "Ethnicity"),
    freq(cohort, region_9, "Region"),
    freq(cohort, imd, "IMD"),
    
    freq(cohort, diabetes, "Diabetes"),
    freq(cohort, chronic_resp_dis, "Chronic respiratory disease"),
    freq(cohort, obese, "Obesity"),
    freq(cohort, hypertension, "Hypertension"),
    freq(cohort, asthma, "Asthma"),
    
    freq(cohort, chronic_cardiac_dis, "Chronic cardiac disease"),
    freq(cohort, lung_cancer, "Lung cancer"),
    freq(cohort, haem_cancer, "Haematological cancer"),
    freq(cohort, other_cancer, "Other cancer"),
    freq(cohort, chronic_liver_dis, "Chronic liver disease"),
    
    freq(cohort, other_neuro, "Other neurological disease"),
    freq(cohort, organ_transplant, "Organ transplant"),
    freq(cohort, dysplenia, "Dysplenia"),
    freq(cohort, hiv, "HIV"),
    freq(cohort, permanent_immunodef, "Other permanent immunodeficiency"),
    
    freq(cohort, ra_sle_psoriasis, "RA/SLE/psoriasis"),
    freq(cohort, smoking_status, "Smoking status")
  ) 
  
}


##### Create separate table/csv file for each cohort #####


table1_covid2020 <- combine(covid20)
write.csv(table1_covid2020, here::here("output", "tabfig", "table1_covid_2020.csv"),
                                       row.names = FALSE)

table1_covid2021 <- combine(covid21)
write.csv(table1_covid2021, here::here("output", "tabfig", "table1_covid_2021.csv"),
                                       row.names = FALSE)

table1_covid2022 <- combine(covid22)
write.csv(table1_covid2022, here::here("output", "tabfig", "table1_covid_2022.csv"),
                                       row.names = FALSE)
          
table1_covidhosp2020 <- combine(covidhosp20)
write.csv(table1_covidhosp2020, here::here("output", "tabfig", "table1_covid_hosp_2020.csv"),
          row.names = FALSE)

table1_covidhosp2021 <- combine(covidhosp21)
write.csv(table1_covidhosp2021, here::here("output", "tabfig", "table1_covid_hosp_2021.csv"),
          row.names = FALSE)

table1_covidhosp2022 <- combine(covidhosp22)
write.csv(table1_covidhosp2022, here::here("output", "tabfig", "table1_covid_hosp_2022.csv"),
          row.names = FALSE)

table1_pneumo2019 <- combine(pneumo19)
write.csv(table1_pneumo2019, here::here("output", "tabfig", "table1_pneumo_2019.csv"),
          row.names = FALSE)

table1_gen2019 <- combine(gen19)
write.csv(table1_gen2019, here::here("output", "tabfig", "table1_gen_2019.csv"),
          row.names = FALSE)

table1_gen2020 <- combine(gen20)
write.csv(table1_gen2020, here::here("output", "tabfig", "table1_gen_2020.csv"),
          row.names = FALSE)

table1_gen2021 <- combine(gen21)
write.csv(table1_gen2021, here::here("output", "tabfig", "table1_gen_2021.csv"),
          row.names = FALSE)

table1_gen2022 <- combine(gen22)
write.csv(table1_gen2021, here::here("output", "tabfig", "table1_gen_2022.csv"),
          row.names = FALSE)


##################################################################




# quantile <- scales::percent(c(.25,.5,.75))

# stats <- function(data, group){
  
#   quantile <- scales::percent(c(.25,.5,.75))
  
#   med <- data %>% 
#     summarise( p25 = quantile(age, .25, na.rm = TRUE),
#                median = quantile(age, .5, na.rm = TRUE),
#                p75 = quantile(age, .75, na.rm = TRUE)) %>%
#     mutate(cohort = group)
  
#   return(med)
# }

# median_age <- rbind(
#   stats(covid20, "COVID 2020"),
#   stats(covid21, "COVID 2021"),
#   stats(covid22, "COVID 2022"),
#   stats(covidhosp20, "COVID hospitalised 2020"),
#   stats(covidhosp21, "COVID hospitalised 2021"),
#   stats(pneumo19, "Pneumonia 2019"),
#   stats(gen19, "General 2019"),
#   stats(gen20, "General 2020"),
#   stats(gen21, "General 2021")
  
# )

